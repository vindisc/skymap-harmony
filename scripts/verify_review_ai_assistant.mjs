import fs from 'node:fs';

const editorPageSource = fs.readFileSync('entry/src/main/ets/pages/EditorPage.ets', 'utf8');
const serviceSource = fs.readFileSync('entry/src/main/ets/services/ReviewAssistantService.ets', 'utf8');
const panelSource = fs.readFileSync('entry/src/main/ets/components/ReviewAssistantPanel.ets', 'utf8');
const readmeSource = fs.readFileSync('README.md', 'utf8');

let failed = false;

function assert(condition, message) {
  if (!condition) {
    failed = true;
    console.error(message);
  }
}

[
  'export interface ReviewAssistantInsight',
  'export class ReviewAssistantService',
  'static analyzeDocument(document: ReviewCardDocument): ReviewAssistantInsight',
  'suggestedJudgementReason',
  'draftActions'
].forEach((token) => {
  assert(serviceSource.includes(token), `ReviewAssistantService 缺少关键 token: ${token}`);
});

[
  'export struct ReviewAssistantPanel',
  'AI 复盘助手',
  '下一步最值得补什么',
  '判断建议',
  '可直接带入的建议'
].forEach((token) => {
  assert(panelSource.includes(token), `ReviewAssistantPanel 缺少关键 token: ${token}`);
});

[
  "import { ReviewAssistantPanel } from '../components/ReviewAssistantPanel';",
  'ReviewAssistantService.analyzeDocument(nextDocument)',
  'private applyAssistantDraft(action: ReviewAssistantDraftAction): void',
  'ToastService.show(this.getUIContext(), `${action.label}已带入`);',
  'ReviewAssistantPanel({'
].forEach((token) => {
  assert(editorPageSource.includes(token), `EditorPage 缺少 AI 助手接入 token: ${token}`);
});

[
  '编辑页内提供 `AI 复盘助手`',
  '当前为端内本地推理，不上传照片和复盘内容'
].forEach((token) => {
  assert(readmeSource.includes(token), `README 缺少 AI 助手说明: ${token}`);
});

if (failed) {
  process.exit(1);
}

console.log('verify_review_ai_assistant: OK');
