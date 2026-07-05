import {
  DEFAULT_REVIEW_TITLE,
  normalizeReviewJudgement,
  ReviewCardDocument,
  ReviewJudgementStatus
} from '../model/ReviewCardModel';

export interface ReviewAssistantPromptItem {
  key: string;
  label: string;
  question: string;
  reason: string;
}

export interface ReviewAssistantDraftAction {
  key: string;
  label: string;
  targetField: string;
  text: string;
}

export interface ReviewAssistantInsight {
  readinessScore: number;
  completedFieldCount: number;
  totalFieldCount: number;
  summary: string;
  nextQuestion: string;
  suggestedJudgement: ReviewJudgementStatus;
  suggestedJudgementReason: string;
  strengths: Array<string>;
  missingPrompts: Array<ReviewAssistantPromptItem>;
  draftActions: Array<ReviewAssistantDraftAction>;
}

interface ReviewAssistantFieldConfig {
  key: string;
  label: string;
  question: string;
  reason: string;
}

const ASSISTANT_FIELD_CONFIGS: Array<ReviewAssistantFieldConfig> = [
  {
    key: 'title',
    label: '标题',
    question: '如果只能用一句判断性标题概括这张照片，你会怎么命名？',
    reason: '标题还没有把你真正要验证的问题说出来。'
  },
  {
    key: 'visualFocus',
    label: '视觉落点',
    question: '第一眼到底会先落到哪里？尽量说成一个明确对象。',
    reason: '没有第一落点，后面的判断都容易漂。'
  },
  {
    key: 'focusReason',
    label: '落点原因',
    question: '它为什么会先被看到？是亮度、位置、颜色还是动作？',
    reason: '你还没有把“先看到”变成可解释的依据。'
  },
  {
    key: 'visualPath',
    label: '视线路径',
    question: '视线接下来会被带去哪里？中间有没有被别的元素打断？',
    reason: '视线流向不清，容易判断不出关系到底有没有成立。'
  },
  {
    key: 'visibleFacts',
    label: '画面事实',
    question: '画面里有哪些看得见的事实，能支撑你的判断？',
    reason: '目前更像感受，还缺少能落到画面里的证据。'
  },
  {
    key: 'coreRelation',
    label: '核心关系',
    question: '这张照片真正成立或不成立的，是哪一组关系？',
    reason: '你还没有把最该被验证的关系抽出来。'
  },
  {
    key: 'extendedUnderstanding',
    label: '延伸理解',
    question: '如果把这次判断迁移到下一张照片，你最想记住什么？',
    reason: '还缺少把这次复盘沉淀成方法的那一步。'
  },
  {
    key: 'currentBlocker',
    label: '当前卡点',
    question: '眼下最不确定、最卡住你的点，到底是什么？',
    reason: '卡点不明确，下一次复拍就不知道先改哪一步。'
  }
];

const ASSISTANT_PLACEHOLDER_TOKENS: Array<string> = [
  DEFAULT_REVIEW_TITLE,
  '待填写',
  '暂无记录',
  '未命名复盘',
  '第一眼先看到哪里',
  '为什么它会先被看到',
  '视线接着从哪里走到哪里',
  '画面里有哪些可见事实',
  '最重要的 A ↔ B 关系是什么',
  '这张照片为什么成立或不成立',
  '当前最大问题是什么',
  '当前卡点'
];

function normalizeAssistantText(value: string | undefined): string {
  if (typeof value !== 'string') {
    return '';
  }
  return value.replace(/\s+/g, ' ').trim();
}

function normalizePlaceholderComparison(value: string): string {
  return value.replace(/[？?。.!！:："'“”‘’\s]/g, '');
}

function isPlaceholderText(value: string): boolean {
  const comparisonValue: string = normalizePlaceholderComparison(value);
  if (comparisonValue.length === 0) {
    return true;
  }

  for (let index = 0; index < ASSISTANT_PLACEHOLDER_TOKENS.length; index += 1) {
    const placeholder: string = normalizePlaceholderComparison(ASSISTANT_PLACEHOLDER_TOKENS[index]);
    if (comparisonValue === placeholder) {
      return true;
    }
  }
  return false;
}

function getMeaningfulText(value: string | undefined): string {
  const normalizedValue: string = normalizeAssistantText(value);
  if (isPlaceholderText(normalizedValue)) {
    return '';
  }
  return normalizedValue;
}

function getFieldText(document: ReviewCardDocument, field: string): string {
  switch (field) {
    case 'title':
      return getMeaningfulText(document.content.title);
    case 'visualFocus':
      return getMeaningfulText(document.content.visualFocus);
    case 'focusReason':
      return getMeaningfulText(document.content.focusReason);
    case 'visualPath':
      return getMeaningfulText(document.content.visualPath);
    case 'visibleFacts':
      return getMeaningfulText(document.content.visibleFacts);
    case 'coreRelation':
      return getMeaningfulText(document.content.coreRelation);
    case 'extendedUnderstanding':
      return getMeaningfulText(document.content.extendedUnderstanding);
    case 'currentBlocker':
      return getMeaningfulText(document.content.currentBlocker);
    default:
      return '';
  }
}

function shortenAssistantText(value: string, maxLength: number): string {
  if (value.length <= maxLength) {
    return value;
  }
  return `${value.slice(0, Math.max(0, maxLength - 1))}…`;
}

function hasNegativeBlockerSignal(value: string): boolean {
  if (value.length === 0) {
    return false;
  }
  const lowerValue: string = value.toLocaleLowerCase();
  const negativeTokens: Array<string> = [
    '杂',
    '乱',
    '抢',
    '散',
    '断',
    '空',
    '冲突',
    '失焦',
    '压住',
    '噪',
    '拥挤'
  ];
  for (let index = 0; index < negativeTokens.length; index += 1) {
    if (lowerValue.includes(negativeTokens[index])) {
      return true;
    }
  }
  return false;
}

function buildAssistantSummary(document: ReviewCardDocument): string {
  const visualFocus: string = getFieldText(document, 'visualFocus');
  const focusReason: string = getFieldText(document, 'focusReason');
  const visualPath: string = getFieldText(document, 'visualPath');
  const coreRelation: string = getFieldText(document, 'coreRelation');

  const segments: Array<string> = [];
  if (visualFocus.length > 0) {
    segments.push(`第一眼会落在${visualFocus}`);
  }
  if (focusReason.length > 0) {
    segments.push(`原因是${focusReason}`);
  }
  if (visualPath.length > 0) {
    segments.push(`视线会继续${visualPath}`);
  }
  if (coreRelation.length > 0) {
    segments.push(`最终要验证的是${coreRelation}`);
  }

  if (segments.length === 0) {
    return '先把第一眼落点和你真正想验证的关系说清，助手才能给出更像样的复盘建议。';
  }
  return `${segments.join('，')}。`;
}

function buildAssistantStrengths(document: ReviewCardDocument): Array<string> {
  const strengths: Array<string> = [];
  const visualFocus: string = getFieldText(document, 'visualFocus');
  const focusReason: string = getFieldText(document, 'focusReason');
  const visualPath: string = getFieldText(document, 'visualPath');
  const visibleFacts: string = getFieldText(document, 'visibleFacts');
  const coreRelation: string = getFieldText(document, 'coreRelation');
  const extendedUnderstanding: string = getFieldText(document, 'extendedUnderstanding');

  if (visualFocus.length > 0 && focusReason.length > 0) {
    strengths.push('你已经把“先看到哪里”和“为什么先看到”连起来了。');
  }
  if (visualPath.length > 0) {
    strengths.push('你开始描述视线怎么在画面里移动，这对判断节奏很有帮助。');
  }
  if (visibleFacts.length > 0) {
    strengths.push('你已经在用画面事实支撑判断，而不只是停留在感觉上。');
  }
  if (coreRelation.length > 0) {
    strengths.push('你已经抓到要验证的核心关系，复盘不容易跑偏。');
  }
  if (extendedUnderstanding.length > 0) {
    strengths.push('你已经在把单次复盘转成可迁移的方法论。');
  }

  return strengths;
}

function buildMissingPrompts(document: ReviewCardDocument): Array<ReviewAssistantPromptItem> {
  return ASSISTANT_FIELD_CONFIGS
    .filter((config: ReviewAssistantFieldConfig): boolean => getFieldText(document, config.key).length === 0)
    .map((config: ReviewAssistantFieldConfig): ReviewAssistantPromptItem => {
      return {
        key: config.key,
        label: config.label,
        question: config.question,
        reason: config.reason
      };
    });
}

function buildSuggestedJudgement(document: ReviewCardDocument, missingPrompts: Array<ReviewAssistantPromptItem>): ReviewJudgementStatus {
  const currentJudgement: ReviewJudgementStatus = normalizeReviewJudgement(document.content.judgement);
  const blockerText: string = getFieldText(document, 'currentBlocker');
  const visualPath: string = getFieldText(document, 'visualPath');
  const focusReason: string = getFieldText(document, 'focusReason');
  const coreRelation: string = getFieldText(document, 'coreRelation');
  const visibleFacts: string = getFieldText(document, 'visibleFacts');

  if (currentJudgement !== ReviewJudgementStatus.UNSURE) {
    return currentJudgement;
  }
  if (hasNegativeBlockerSignal(blockerText)) {
    return ReviewJudgementStatus.INVALID;
  }
  if (missingPrompts.length <= 2 &&
    visualPath.length > 0 &&
    focusReason.length > 0 &&
    coreRelation.length > 0 &&
    visibleFacts.length > 0 &&
    blockerText.length === 0) {
    return ReviewJudgementStatus.VALID;
  }
  return ReviewJudgementStatus.UNSURE;
}

function buildSuggestedJudgementReason(
  document: ReviewCardDocument,
  suggestedJudgement: ReviewJudgementStatus,
  missingPrompts: Array<ReviewAssistantPromptItem>
): string {
  const currentJudgement: ReviewJudgementStatus = normalizeReviewJudgement(document.content.judgement);
  const blockerText: string = getFieldText(document, 'currentBlocker');

  if (currentJudgement !== ReviewJudgementStatus.UNSURE) {
    return '你已经手动给出判断，助手这边先沿用你的结论。';
  }
  if (suggestedJudgement === ReviewJudgementStatus.INVALID) {
    return blockerText.length > 0
      ? '当前卡点里已经出现明显的负面信号，先按不成立复盘会更利于找问题。'
      : '画面证据链还没闭合，先按不成立去找断点会更高效。';
  }
  if (suggestedJudgement === ReviewJudgementStatus.VALID) {
    return '关键字段已经连成一条较完整的证据链，可以先按成立继续打磨表述。';
  }
  if (missingPrompts.length > 0) {
    return `还有 ${missingPrompts.length} 个关键字段没说清，暂时保留“待判断”更稳。`;
  }
  return '结论还可以再压一压，先保留“待判断”避免过早下结论。';
}

function buildNextQuestion(document: ReviewCardDocument, missingPrompts: Array<ReviewAssistantPromptItem>): string {
  if (missingPrompts.length > 0) {
    return missingPrompts[0].question;
  }

  const judgement: ReviewJudgementStatus = normalizeReviewJudgement(document.content.judgement);
  if (judgement === ReviewJudgementStatus.UNSURE) {
    return '如果现在必须二选一，你更倾向这张照片成立还是不成立？最硬的一条证据是什么？';
  }
  if (judgement === ReviewJudgementStatus.VALID) {
    return '既然你认为它成立，那最值得复制到下一次拍摄的关键动作是什么？';
  }
  return '既然你认为它不成立，那下次重拍时最先要动的那个变量是什么？';
}

function buildTitleSuggestion(document: ReviewCardDocument): string {
  const coreRelation: string = getFieldText(document, 'coreRelation');
  if (coreRelation.length > 0) {
    return `${shortenAssistantText(coreRelation, 14)}是否成立`;
  }

  const visualFocus: string = getFieldText(document, 'visualFocus');
  if (visualFocus.length > 0) {
    return `${shortenAssistantText(visualFocus, 14)}是否撑住画面`;
  }
  return DEFAULT_REVIEW_TITLE;
}

function buildExtendedUnderstandingSuggestion(document: ReviewCardDocument, summary: string): string {
  const coreRelation: string = getFieldText(document, 'coreRelation');
  const visualFocus: string = getFieldText(document, 'visualFocus');
  const blockerText: string = getFieldText(document, 'currentBlocker');
  const anchor: string = coreRelation.length > 0 ? coreRelation : (visualFocus.length > 0 ? visualFocus : '主体关系');
  if (blockerText.length > 0) {
    return `这次复盘提醒我，判断一张照片时不能只看题材，要看${anchor}有没有被稳定托住；一旦${blockerText}，画面就会立刻松掉。`;
  }
  if (summary.length > 0) {
    return `${summary.replace(/。$/, '')}，说明我后续拍摄时要优先检查${anchor}有没有被真正看见，而不是只顾局部好看。`;
  }
  return `这次复盘更像一次提醒：后续拍摄时要先确认主体关系有没有被真正看见。`;
}

function buildBlockerSuggestion(document: ReviewCardDocument, missingPrompts: Array<ReviewAssistantPromptItem>): string {
  const currentBlocker: string = getFieldText(document, 'currentBlocker');
  if (currentBlocker.length > 0) {
    return currentBlocker;
  }

  if (missingPrompts.length > 0) {
    const promptLabels: Array<string> = missingPrompts
      .slice(0, Math.min(2, missingPrompts.length))
      .map((prompt: ReviewAssistantPromptItem): string => prompt.label);
    return `我还没有把${promptLabels.join('和')}说清，导致结论依据还不够稳。`;
  }

  return '目前最大的卡点是证据链还不够短而硬，需要把落点、原因和核心关系压成一句能自证的话。';
}

function buildDraftActions(
  document: ReviewCardDocument,
  summary: string,
  suggestedJudgement: ReviewJudgementStatus,
  missingPrompts: Array<ReviewAssistantPromptItem>
): Array<ReviewAssistantDraftAction> {
  const actions: Array<ReviewAssistantDraftAction> = [];
  const currentTitle: string = getFieldText(document, 'title');
  const titleSuggestion: string = buildTitleSuggestion(document);
  const extendedUnderstandingSuggestion: string = buildExtendedUnderstandingSuggestion(document, summary);
  const blockerSuggestion: string = buildBlockerSuggestion(document, missingPrompts);
  const currentJudgement: ReviewJudgementStatus = normalizeReviewJudgement(document.content.judgement);

  if (currentTitle.length === 0 && titleSuggestion.length > 0) {
    actions.push({
      key: 'title',
      label: '带入标题建议',
      targetField: 'title',
      text: titleSuggestion
    });
  }

  if (extendedUnderstandingSuggestion.length > 0 &&
    extendedUnderstandingSuggestion !== getFieldText(document, 'extendedUnderstanding')) {
    actions.push({
      key: 'extendedUnderstanding',
      label: '带入延伸理解',
      targetField: 'extendedUnderstanding',
      text: extendedUnderstandingSuggestion
    });
  }

  if (blockerSuggestion.length > 0 && blockerSuggestion !== getFieldText(document, 'currentBlocker')) {
    actions.push({
      key: 'currentBlocker',
      label: '带入当前卡点',
      targetField: 'currentBlocker',
      text: blockerSuggestion
    });
  }

  if (currentJudgement !== suggestedJudgement) {
    actions.push({
      key: 'judgement',
      label: '采用判断建议',
      targetField: 'judgement',
      text: suggestedJudgement
    });
  }

  return actions.slice(0, 4);
}

export function createEmptyReviewAssistantInsight(): ReviewAssistantInsight {
  return {
    readinessScore: 0,
    completedFieldCount: 0,
    totalFieldCount: ASSISTANT_FIELD_CONFIGS.length,
    summary: '先开始填写复盘，助手会根据你的内容实时给建议。',
    nextQuestion: '第一眼先看到哪里？',
    suggestedJudgement: ReviewJudgementStatus.UNSURE,
    suggestedJudgementReason: '先补充复盘内容，再让助手判断更合适。',
    strengths: [],
    missingPrompts: [],
    draftActions: []
  };
}

export class ReviewAssistantService {
  static analyzeDocument(document: ReviewCardDocument): ReviewAssistantInsight {
    const totalFieldCount: number = ASSISTANT_FIELD_CONFIGS.length;
    const missingPrompts: Array<ReviewAssistantPromptItem> = buildMissingPrompts(document);
    const completedFieldCount: number = totalFieldCount - missingPrompts.length;
    const readinessScore: number = Math.round(completedFieldCount * 100 / totalFieldCount);
    const summary: string = buildAssistantSummary(document);
    const suggestedJudgement: ReviewJudgementStatus = buildSuggestedJudgement(document, missingPrompts);
    return {
      readinessScore: readinessScore,
      completedFieldCount: completedFieldCount,
      totalFieldCount: totalFieldCount,
      summary: summary,
      nextQuestion: buildNextQuestion(document, missingPrompts),
      suggestedJudgement: suggestedJudgement,
      suggestedJudgementReason: buildSuggestedJudgementReason(document, suggestedJudgement, missingPrompts),
      strengths: buildAssistantStrengths(document).slice(0, 3),
      missingPrompts: missingPrompts.slice(0, 3),
      draftActions: buildDraftActions(document, summary, suggestedJudgement, missingPrompts)
    };
  }
}
