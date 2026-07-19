import { ReviewCardDocument } from '../model/ReviewCardModel';
import { normalizeFrameConfig } from '../model/FrameConfigModel';
import { resolveTemplate, TemplateId } from '../model/TemplateModel';

export function applyTemplateToDocument(
  document: ReviewCardDocument,
  templateId: TemplateId | string
): ReviewCardDocument {
  const template = resolveTemplate(templateId);
  return {
    version: document.version,
    projectId: document.projectId,
    imageUri: document.imageUri,
    imageWidth: document.imageWidth,
    imageHeight: document.imageHeight,
    imageSizeFallbackUsed: document.imageSizeFallbackUsed,
    content: document.content,
    config: {
      templateId: template.id,
      layoutMode: document.config.layoutMode,
      background: document.config.background,
      textSize: document.config.textSize,
      templateLevel: template.level,
      frame: normalizeFrameConfig(undefined, template.defaults.frame)
    },
    createdAt: document.createdAt,
    updatedAt: document.updatedAt,
    exif: document.exif
  };
}
