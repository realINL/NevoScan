import torch
import torch.nn as nn
import torch.nn.functional as F
from torchvision import models
import coremltools as ct

class ResNetFeatMask(nn.Module):
    def __init__(self, num_classes=2, pretrained_backbone=True):
        super().__init__()
        backbone = models.resnet50(pretrained=pretrained_backbone)
        self.features = nn.Sequential(*(list(backbone.children())[:-2]))
        self.avgpool = backbone.avgpool
        self.fc = nn.Linear(backbone.fc.in_features, num_classes)

    def forward(self, x, seg_mask):
        feat = self.features(x)

        mask_small = F.interpolate(seg_mask, size=feat.shape[2:], mode='nearest')
        feat = feat * mask_small

        out = self.avgpool(feat)
        out = torch.flatten(out, 1)
        return self.fc(out)

device = torch.device("cpu")

model = ResNetFeatMask(num_classes=2, pretrained_backbone=False)
model.load_state_dict(torch.load("best_f1_resnet_3.05.25.pth", map_location=device))
model.eval()

dummy_img = torch.randn(1, 3, 256, 256)
dummy_mask = torch.randn(1, 1, 256, 256)

traced_model = torch.jit.trace(model, (dummy_img, dummy_mask))


mlmodel = ct.convert(
    traced_model,
    inputs=[
        ct.ImageType(
            name="image",
            shape=dummy_img.shape,
            scale=1/255.0,
            bias=[-0.485/0.229, -0.456/0.224, -0.406/0.225],  # Normalize
        ),
        ct.TensorType(
            name="mask",
            shape=dummy_mask.shape
        )
    ],
    outputs=[
        ct.TensorType(name="output")
    ],
    minimum_deployment_target=ct.target.iOS15
)

mlmodel.save("ResNetFeatMask.mlpackage")