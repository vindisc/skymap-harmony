export const ENABLE_RDB_DIAGNOSTICS_ENTRY: boolean = false;

export const REVIEW_FLOW_IMPORT_PENDING_TEXT: string = '正在打开照片…';
export const REVIEW_FLOW_IMPORT_FAILED_TEXT: string = '照片导入失败，请重新选择';
export const REVIEW_FLOW_PENDING_IMPORT_SUCCESS_TEXT: string = '已加入待复盘';
export const REVIEW_FLOW_PENDING_IMPORT_FAILED_TEXT: string = '加入待复盘失败，请重新选择';

export const REVIEW_FLOW_SAVE_PENDING_TEXT: string = '保存中…';
export const REVIEW_FLOW_SAVE_SUCCESS_TEXT: string = '复盘已保存';
export const REVIEW_FLOW_SAVE_FAILED_TEXT: string = '保存失败，请稍后重试';
export const REVIEW_FLOW_TEMPLATE_FRAME_RESET_TEXT: string = '已切换模板，边框参数已重置';

export const REVIEW_FLOW_EXPORT_PENDING_TEXT: string = '导出中…';
export const REVIEW_FLOW_EXPORT_SUCCESS_TEXT: string = '导出完成';
export const REVIEW_FLOW_IMAGE_EXPORT_SUCCESS_TEXT: string = '已保存到图库最近项目';
export const REVIEW_FLOW_EXPORT_FAILED_TEXT: string = '导出失败，请重试';
export const REVIEW_FLOW_BUNDLE_EXPORT_SUCCESS_TEXT: string = '复盘包已导出到家庭存储';
export const REVIEW_FLOW_BUNDLE_EXPORT_FAILED_TEXT: string = '复盘包导出失败，请重试';
export const REVIEW_FLOW_ORIGINAL_BUNDLE_EXPORT_PENDING_TEXT: string = '正在导出含原图复盘包…';
export const REVIEW_FLOW_ORIGINAL_BUNDLE_EXPORT_SUCCESS_TEXT: string = '含原图复盘包已导出到家庭存储';
export const REVIEW_FLOW_ORIGINAL_BUNDLE_EXPORT_FAILED_TEXT: string = '含原图复盘包导出失败，请重试。';
export const REVIEW_FLOW_ORIGINAL_BUNDLE_EXPORT_READ_FAILED_TEXT: string = '原始照片无法读取，请重新导入。';
export const REVIEW_FLOW_ORIGINAL_BUNDLE_EXPORT_COPY_FAILED_TEXT: string = '原始照片保存失败，请重试。';
export const REVIEW_FLOW_BUNDLE_EXPORT_CONFIG_REQUIRED_TEXT: string = '请先配置家庭存储';
export const REVIEW_FLOW_BUNDLE_EXPORT_CONFIG_INCOMPLETE_TEXT: string = '家庭存储配置不完整，请检查设置';
export const REVIEW_FLOW_BUNDLE_EXPORT_UNREACHABLE_TEXT: string = '无法连接家庭存储。请连接家庭 Wi-Fi 或 VPN 后重试。';
export const REVIEW_FLOW_BUNDLE_EXPORT_AUTH_FAILED_TEXT: string = '家庭存储账号或密码不正确，请检查设置';
export const REVIEW_FLOW_BUNDLE_EXPORT_DIRECTORY_FAILED_TEXT: string = '家庭存储目录创建失败，请稍后重试';

export const REVIEW_FLOW_DELETE_PENDING_TEXT: string = '删除中…';
export const REVIEW_FLOW_DELETE_SUCCESS_TEXT: string = '复盘已删除';
export const REVIEW_FLOW_DELETE_FAILED_TEXT: string = '删除失败，请重试';
export const REVIEW_FLOW_PENDING_DELETE_SUCCESS_TEXT: string = '待复盘照片已删除';
export const REVIEW_FLOW_PENDING_DELETE_FAILED_TEXT: string = '删除失败，请重试';
export const REVIEW_FLOW_HOME_RELOAD_FAILED_TEXT: string = '复盘记录暂时无法刷新，可稍后重试。';
export const REVIEW_FLOW_HOME_COPY_ISSUE_TEXT: string = '复制问题信息';
export const REVIEW_FLOW_HOME_COPY_ISSUE_SUCCESS_TEXT: string = '已复制问题信息';
export const REVIEW_FLOW_HOME_COPY_ISSUE_FAILED_TEXT: string = '复制问题信息失败';

export const FEEDBACK_HERO_IMAGE_SAVE_FAILED_TEXT: string = '图片保存失败，请重试';
export const FEEDBACK_HERO_IMAGE_PARTIAL_FAILED_TEXT: string = '部分图片无法保存，请重试';
export const FEEDBACK_HERO_IMAGE_DELETE_FAILED_TEXT: string = '删除失败，请重试';
export const FEEDBACK_HERO_IMAGE_RESTORED_TEXT: string = '已恢复默认首页图片';
export const FEEDBACK_HERO_IMAGE_UPDATED_TEXT: string = '首页图片已更新';
export const FEEDBACK_HERO_IMAGE_CLEAR_FAILED_TEXT: string = '清空失败，请重试';

export const FEEDBACK_REVIEWER_SAVE_SUCCESS_TEXT: string = '已保存复盘人';
export const FEEDBACK_REVIEWER_SAVE_FAILED_TEXT: string = '保存失败，请稍后重试';

export const FEEDBACK_CLIPBOARD_COPY_SUCCESS_TEXT: string = '已复制复盘数据';
export const FEEDBACK_CLIPBOARD_COPY_FAILED_TEXT: string = '复制失败，请稍后重试';

export const FEEDBACK_WIDGET_BACKGROUND_FAILED_TEXT: string = '卡片背景保存失败，请重试';
export function formatFeedbackWidgetBackgroundSuccess(label: string): string {
  return `卡片背景已切换为${label}`;
}

export function formatFeedbackImportSummary(ok: number, failed: number): string {
  return `成功导入：${ok}，失败：${failed}`;
}

export function formatFeedbackPendingImportBatchSuccess(count: number): string {
  return `已加入待复盘（${count} 张）`;
}

export const FEEDBACK_RDB_DIAG_SUCCESS_TEXT: string = 'RDB开发诊断通过';
export const FEEDBACK_RDB_DIAG_FAILED_TEXT: string = 'RDB开发诊断失败，查看日志';
export const FEEDBACK_RDB_DIAG_EXCEPTION_TEXT: string = 'RDB开发诊断异常，查看日志';

export const FEEDBACK_EXPORT_TIMEOUT_TEXT: string = '导出超时，请重试';

export const FEEDBACK_HOME_STORAGE_SAVE_SUCCESS_TEXT: string = '已保存家庭存储设置';
export const FEEDBACK_HOME_STORAGE_SAVE_FAILED_TEXT: string = '保存失败，请稍后重试';
export const FEEDBACK_HOME_STORAGE_ROUNDTRIP_MISMATCH_TEXT: string = '已保存，但回读不一致';

export const FEEDBACK_PROGRESS_RENDER_EXPORT_IMAGE_TEXT: string = '渲染导出图…';
export const FEEDBACK_PROGRESS_SAVE_TO_GALLERY_TEXT: string = '保存到相册…';
export const FEEDBACK_PROGRESS_WRITE_HOME_STORAGE_TEXT: string = '写入家庭存储…';
export const FEEDBACK_PROGRESS_COLLECT_ORIGINAL_BUNDLE_TEXT: string = '整理原图和复盘数据…';
