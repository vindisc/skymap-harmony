type SettingsRefreshListener = (token: number, reason: string) => void;

export class SettingsRefreshService {
  private static refreshToken: number = 0;
  private static lastReason: string = '';
  private static listeners: Array<SettingsRefreshListener> = [];

  static notifySettingsChanged(reason: string): number {
    SettingsRefreshService.refreshToken += 1;
    SettingsRefreshService.lastReason = reason;
    console.info(`[SettingsRefresh] token=${SettingsRefreshService.refreshToken}, reason=${reason}`);
    SettingsRefreshService.listeners.forEach((listener: SettingsRefreshListener): void => {
      try {
        listener(SettingsRefreshService.refreshToken, reason);
      } catch (error) {
        console.warn(`[SettingsRefresh] listener failed: ${error}`);
      }
    });
    return SettingsRefreshService.refreshToken;
  }

  static subscribe(listener: SettingsRefreshListener): void {
    if (SettingsRefreshService.listeners.indexOf(listener) >= 0) {
      return;
    }
    SettingsRefreshService.listeners.push(listener);
  }

  static unsubscribe(listener: SettingsRefreshListener): void {
    SettingsRefreshService.listeners = SettingsRefreshService.listeners.filter(
      (item: SettingsRefreshListener): boolean => item !== listener
    );
  }

  static getRefreshToken(): number {
    return SettingsRefreshService.refreshToken;
  }

  static getLastReason(): string {
    return SettingsRefreshService.lastReason;
  }
}
