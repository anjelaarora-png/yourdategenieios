/**
 * Validates that each Playbook category has at least 50 tips per gender combination.
 * Run: npx tsx scripts/validate-playbook-tips.mts
 */
import {
  PLAYBOOK_CATEGORIES,
  getPlaybookTips,
  type PlaybookComboKey,
} from "../src/data/playbookContent";

const MIN_TIPS = 50;
const COMBOS: PlaybookComboKey[] = ["default", "male_female", "female_male", "male_male", "female_female"];

let failed = false;
for (const category of PLAYBOOK_CATEGORIES) {
  for (const combo of COMBOS) {
    const tips = getPlaybookTips(category.id, combo);
    if (tips.length < MIN_TIPS) {
      console.error(
        `[FAIL] ${category.id} / ${combo}: ${tips.length} tips (required >= ${MIN_TIPS})`
      );
      failed = true;
    }
  }
}
if (failed) {
  process.exit(1);
}
console.log(
  `[OK] All ${PLAYBOOK_CATEGORIES.length} categories have >= ${MIN_TIPS} tips per combination.`
);
