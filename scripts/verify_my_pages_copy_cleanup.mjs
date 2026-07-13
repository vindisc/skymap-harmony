import fs from 'node:fs';

const readPage = (name) => fs.readFileSync(`entry/src/main/ets/pages/${name}.ets`, 'utf8');
const pages = {
  motion: readPage('MotionSettingsPage'),
  my: readPage('MyPage'),
  hero: readPage('HomeHeroImagePage'),
  storage: readPage('HomeStoragePage'),
  reviewer: readPage('ReviewerProfilePage'),
  sync: readPage('SyncCenterPage'),
  widget: readPage('WidgetCardBackgroundPage'),
  legacySettings: readPage('ReviewSettingsPage')
};

let failed = false;

function assert(condition, message) {
  if (!condition) {
    failed = true;
    console.error(message);
  }
}

function forbid(source, copy, page) {
  assert(!source.includes(copy), `${page} 仍包含解释性文案：${copy}`);
}

[
  '控制里程碑动画与页面转场的强度。',
  '分层转场、弹性回应与里程碑动画',
  '保留方向与层次，关闭弹性超冲和庆祝粒子',
  '只保留必要的短过渡，不播放分批与粒子动画'
].forEach((copy) => forbid(pages.motion, copy, 'MotionSettingsPage'));

[
  '应用于桌面卡片',
  '里程碑动画与页面转场的强度',
  '删除时的粒子星河动画',
  '复盘与原图保存到手机文件，卸载后仍可恢复',
  '支持多选备份，去重合并后整体恢复',
  '正在运行，仅用于开发验证',
  '会自动轮播'
].forEach((copy) => forbid(pages.my, copy, 'MyPage'));
assert(!/^\s+value:/m.test(pages.my), 'MyPage 设置入口必须保持单行，不应再渲染第二行说明');

[
  '已添加到首页图片',
  '首页展示图',
  '当前展示，固定保留',
  '固定保留，自定义图片会优先轮播',
  '可一次选择多张，加入首页轮播'
].forEach((copy) => forbid(pages.hero, copy, 'HomeHeroImagePage'));

[
  '选定后会立即同步到桌面卡片。回纹以低对比度铺在底层，不影响数据阅读。',
  '清爽留白',
  '低对比度连续铺陈',
  '四角沿边，保留中央留白'
].forEach((copy) => forbid(pages.widget, copy, 'WidgetCardBackgroundPage'));

forbid(pages.legacySettings, '连接与凭据', 'ReviewSettingsPage');
assert(!pages.sync.includes('SettingsLinkRow'), 'SyncCenterPage 不应保留与详情卡重复的摘要说明卡');

assert(
  /SettingsPageHeader\(\{ title: '显示与动效' \}\)[\s\S]*?\.height\('100%'\)\s*\.justifyContent\(FlexAlign\.Start\)/.test(pages.motion),
  'MotionSettingsPage 内容必须全高并固定从顶部开始布局'
);

[
  ['my', "title: '我的'"],
  ['motion', "title: '显示与动效'"],
  ['hero', "title: '首页图片'"],
  ['storage', "title: '家庭存储'"],
  ['reviewer', "title: '复盘人'"],
  ['sync', "title: '同步中心'"],
  ['widget', "title: '卡片背景'"]
].forEach(([page, marker]) => assert(pages[page].includes(marker), `${page} 缺少页面标题`));

if (failed) {
  process.exit(1);
}

console.log('我的及子页面文案与顶部布局检查通过');
