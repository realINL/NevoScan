import logging
import torch
import torch.nn as nn
import torchvision.models as models
import torchvision.transforms as transforms
from PIL import Image
import numpy as np
import torch.nn.functional as F
from ultralytics import YOLO
import cv2
from io import BytesIO

from app.Config.config import Config
from app.Nevoscan.ResNetFeatMask import  ResNetFeatMask
from app.Models.Schemas import InferenceResult, CompletedInferenceResult, NoObjectInferenceResult, ResultStatus

class Nevoscan:

    __YOLO_MODEL = None
    __SEG_MOODEL = None
    __CLASS_MODEL = None
    __DEVICE = None

    def __init__(self):

        self.__DEVICE = torch.device(Config.DEVICE)

        # Загрузка yolo
        yolo_file = Config.YOLO_FILE
        if not yolo_file or not yolo_file.exists():
            logging.error(f"Не найден файл {yolo_file}")
        else:
            try:
                self.__YOLO_MODEL = YOLO(str(yolo_file))
            except Exception as e:
                self.__YOLO_MODEL = None
                logging.error(f"Ошибка загрузки YOLO модели: {e}")

        # Загрузка DeepLabV3
        deeplab_file = Config.DEEPLAB_FILE
        if not deeplab_file or not deeplab_file.exists():
            logging.error(f"Не найден файл {deeplab_file}")
        else:
            try:
                self.__SEG_MOODEL = models.segmentation.deeplabv3_resnet101(pretrained=True)
                self.__SEG_MOODEL.classifier[4] = nn.Conv2d(256, 1, kernel_size=1)
                self.__SEG_MOODEL.load_state_dict(torch.load(deeplab_file, map_location=self.__DEVICE))
                self.__SEG_MOODEL.to(self.__DEVICE)
            except Exception as e:
                self.__SEG_MOODEL = None
                logging.error(f"Ошибка загрузки DeepLabV3 модели: {e}")

        # Загрузка ResNet
        resnet_file = Config.RESNET_FILE
        if not resnet_file or not resnet_file.exists():
            logging.error(f"Не найден файл {resnet_file}")
        else:
            try:
                self.__CLASS_MODEL = ResNetFeatMask(num_classes=2, pretrained_backbone=True).to(self.__DEVICE)
                self.__CLASS_MODEL.load_state_dict(torch.load(resnet_file, map_location=self.__DEVICE))
                self.__CLASS_MODEL.to(self.__DEVICE)
            except Exception as e:
                self.__CLASS_MODEL = None
                logging.error(f"Ошибка загрузки ResNet модели: {e}")

        logging.info("Nevoscan запущен успешно")


    # Трансформации для классификации
    __class_image_transform = transforms.Compose([
        transforms.Resize((256, 256)),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
    ])
    __class_mask_transform = transforms.Compose([
        transforms.Grayscale(num_output_channels=1),
        transforms.Resize((256, 256), interpolation=transforms.InterpolationMode.NEAREST),
        transforms.ToTensor(),
        transforms.Lambda(lambda t: (t > 0.5).float())
    ])

    # Функции
    def __preprocess(self, uploaded_file):
        """Предобработка изображения"""
        try:
            image = Image.open(BytesIO(uploaded_file))
            image_np = np.array(image)
            if image_np.shape[2] == 4:  # Если есть альфа-канал
                image_np = image_np[:, :, :3]
            return cv2.cvtColor(image_np, cv2.COLOR_RGB2BGR)  # BGR
        except Exception as e:
            raise ValueError(f"Ошибка предобработки изображения: {str(e)}")

    def __detection(self, image):
        """Детекция родинки на изображении"""
        results = self.__YOLO_MODEL(image, imgsz=Config.YOLO_IMAGESIZE, iou=Config.YOLO_IOU, conf=Config.YOLO_CONF, verbose=False)
        # Проверка существует ли объект
        if len(results[0].boxes) == 0:
            return None, image

        box = results[0].boxes.xyxy[0].cpu().numpy()  # [x1, y1, x2, y2]
        return box, image

    def __crop_image(self, image, box):
        """Обрезка изображения"""
        x1, y1, x2, y2 = map(int, box)
        cropped = image[y1:y2, x1:x2]
        return cropped

    def __dullrazor(self, image):
        """Удаляет волосы с фото"""
        image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        gray_scale = cv2.cvtColor(image_rgb, cv2.COLOR_RGB2GRAY)
        kernel = cv2.getStructuringElement(1, (9, 9))
        blackhat = cv2.morphologyEx(gray_scale, cv2.MORPH_BLACKHAT, kernel)
        bhg = cv2.GaussianBlur(blackhat, (3, 3), 0, borderType=cv2.BORDER_DEFAULT)
        ret, mask = cv2.threshold(bhg, 10, 255, cv2.THRESH_BINARY)
        dst = cv2.inpaint(image, mask, 6, cv2.INPAINT_TELEA)
        return dst

    def __segmentation(self, cropped_image):
        """Сегментация изображения"""
        transform = self.__class_image_transform
        image_rgb = cv2.cvtColor(cropped_image, cv2.COLOR_BGR2RGB)
        pil_image = Image.fromarray(image_rgb)
        input_tensor = transform(pil_image).unsqueeze(0).to(self.__DEVICE)

        self.__SEG_MOODEL.eval()
        with torch.no_grad():
            output = self.__SEG_MOODEL(input_tensor)['out']
            output = F.interpolate(output, size=(256, 256), mode="bilinear", align_corners=False)
            preds = torch.sigmoid(output) > 0.5

        mask = preds.squeeze().cpu().numpy().astype(np.uint8)
        mask_resized = cv2.resize(mask, (cropped_image.shape[1], cropped_image.shape[0]))
        return mask_resized

    def __classify(self, image, mask):
        """Классификация изображения"""
        # image_rgb = image
        image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        pil_img = Image.fromarray(image_rgb)
        img_tensor = self.__class_image_transform(pil_img).unsqueeze(0).to(self.__DEVICE)
        mask_uint8 = (mask * 255).astype('uint8')
        pil_mask = Image.fromarray(mask_uint8, mode='L')
        mask_tensor = self.__class_mask_transform(pil_mask).unsqueeze(0).to(self.__DEVICE)

        self.__CLASS_MODEL.eval()
        with torch.no_grad():
            outputs = self.__CLASS_MODEL(img_tensor, seg_mask=mask_tensor)
            probs = torch.softmax(outputs, dim=1)
            prob_malign = probs[0, 1].item()
            prob_benign = probs[0, 0].item()

        threshold = Config.RESNET_THRESHOLD
        print(threshold)
        pred = 1 if prob_malign >= threshold else 0
        print( pred)
        label_map = {0: 'Доброкачественное', 1: 'Злокачественное'}
        result = label_map[pred]
        print(f"t: {threshold}; prob_m: {prob_malign} pred: {pred}; res: {result}")
        return result, prob_benign, prob_malign

    def predict(self, uploaded_file) -> InferenceResult:
        if uploaded_file is not None:
            try:
                # Чтение изображения
                image_np = self.__preprocess(uploaded_file)

                # Детекция
                box, _ = self.__detection(image_np) #BGR
                if box is None:
                    logging.warning("Родинка не обнаружена. Пожалуйста, загрузите другое фото.")
                    return NoObjectInferenceResult(status=ResultStatus.NO_OBJECT)

                # Обрезка
                cropped = self.__crop_image(image_np, box) # BGR

                # Удаление волос
                # hair_removed = self.__dullrazor(cropped) # BGR
                # hair_removed_rgb = cv2.cvtColor(hair_removed, cv2.COLOR_BGR2RGB) # RGB

                # Сегментация
                mask = self.__segmentation(cropped)

                # Классификация
                result, prob_benign, prob_malign = self.__classify(cropped, mask)

                print(f"Злокачественное: {prob_malign:.2%}")
                print(f"Доброкачественное: {prob_benign:.2%}")
                print(result)
                
                return CompletedInferenceResult(
                    status=ResultStatus.COMPLETED,
                    result=result,
                    probability_malign=prob_malign,
                    probability_benign=prob_benign,
                    cropped_image=cropped,
                    mask=mask,
                )

            except ValueError as e:
                return NoObjectInferenceResult(status=ResultStatus.ERROR)
            except Exception as e:
                logging.error(f"Ошибка обработки изображения: {e}")
                return NoObjectInferenceResult(
                    status=ResultStatus.ERROR,
                )

# module = Nevoscan()
#
# with open("../../.dev/dd.jpg","rb") as f:
#     img = f.read()
# module.predict(img)