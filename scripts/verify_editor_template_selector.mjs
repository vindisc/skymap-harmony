import fs from 'node:fs';

const sourcePath = 'entry/src/main/ets/pages/EditorPage.ets';
const source = fs.readFileSync(sourcePath, 'utf8');

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

assert(
  source.includes('TemplateLevelTabBar({'),
  'EditorPage must keep the compact template level tabs.'
);
assert(
  source.includes('this.switchTemplate(this.resolveDefaultTemplateId(level));'),
  'Changing a template level must still select its default template.'
);
assert(
  !source.includes("import { TemplateChipStrip }"),
  'EditorPage must not import the redundant single-template card strip.'
);
assert(
  !source.includes('TemplateChipStrip({'),
  'EditorPage must not render the redundant single-template card strip.'
);

console.log('editor template selector verified: level tabs remain and redundant template card strip is absent');
