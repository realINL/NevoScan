import torch
import torch.nn as nn
import torchvision.models as models
import torch.nn.functional as F

# Класс ResNetFeatMask
class ResNetFeatMask(nn.Module):
    def __init__(self, num_classes=2, pretrained_backbone=True):
        super().__init__()
        backbone = models.resnet50(pretrained=pretrained_backbone)
        self.features = nn.Sequential(*(list(backbone.children())[:-2]))
        self.avgpool = backbone.avgpool
        self.fc = nn.Linear(backbone.fc.in_features, num_classes)

    def forward(self, x, seg_mask=None):
        feat = self.features(x)
        if seg_mask is not None:
            mask_small = F.interpolate(seg_mask, size=feat.shape[2:], mode='nearest')
            feat = feat * mask_small
        out = self.avgpool(feat)
        out = torch.flatten(out, 1)
        return self.fc(out)
