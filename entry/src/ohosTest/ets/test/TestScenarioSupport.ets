import { Want } from '@kit.AbilityKit';
import {
  abilityDelegatorRegistry,
  Driver
} from '@kit.TestKit';

const ENTRY_ABILITY_NAME: string = 'EntryAbility';
const ENTRY_MODULE_NAME: string = 'entry';
const SCENARIO_SETTLE_DELAY_MS: number = 650;

export async function launchTestScenario(scenario: string): Promise<Driver> {
  const delegator = abilityDelegatorRegistry.getAbilityDelegator();
  const args = abilityDelegatorRegistry.getArguments();
  const want: Want = {
    bundleName: args.bundleName,
    moduleName: ENTRY_MODULE_NAME,
    abilityName: ENTRY_ABILITY_NAME,
    parameters: {
      testScenario: scenario
    }
  };
  await delegator.startAbility(want);
  const driver: Driver = Driver.create();
  await driver.delayMs(SCENARIO_SETTLE_DELAY_MS);
  return driver;
}
