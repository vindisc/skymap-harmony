export enum MotionCeremonyEventKind {
  REVIEW_QUEUE_CLEARED = 'review-queue-cleared',
  STREAK_RECORD = 'streak-record',
  SMB_FIRST_CONNECT = 'smb-first-connect'
}

type MotionCeremonyEventListener = (kind: MotionCeremonyEventKind) => boolean;

// 约束：每种 MotionCeremonyEventKind 只应有唯一订阅方。emit 返回的 handled 语义是
// “该 kind 的唯一订阅方是否接住了这次事件”；不支持多方共同消费。
export class MotionCeremonyEventService {
  private static listeners: Array<MotionCeremonyEventListener> = [];
  private static pendingKinds: Array<MotionCeremonyEventKind> = [];

  static subscribe(listener: MotionCeremonyEventListener): void {
    if (MotionCeremonyEventService.listeners.indexOf(listener) >= 0) {
      console.warn('[MotionCeremonyEventService] listener 已订阅，已跳过重复注册');
      MotionCeremonyEventService.consumePending(listener);
      return;
    }
    MotionCeremonyEventService.listeners.push(listener);
    MotionCeremonyEventService.consumePending(listener);
  }

  static unsubscribe(listener: MotionCeremonyEventListener): void {
    MotionCeremonyEventService.listeners = MotionCeremonyEventService.listeners.filter(
      (item: MotionCeremonyEventListener): boolean => item !== listener
    );
  }

  static enqueue(kind: MotionCeremonyEventKind): void {
    if (MotionCeremonyEventService.pendingKinds.indexOf(kind) >= 0) {
      return;
    }
    MotionCeremonyEventService.pendingKinds.push(kind);
  }

  static consumePending(listener: MotionCeremonyEventListener): void {
    const pendingKinds: Array<MotionCeremonyEventKind> = MotionCeremonyEventService.pendingKinds.slice();
    pendingKinds.forEach((kind: MotionCeremonyEventKind): void => {
      if (!MotionCeremonyEventService.tryHandle(listener, kind)) {
        return;
      }
      MotionCeremonyEventService.pendingKinds = MotionCeremonyEventService.pendingKinds.filter(
        (pendingKind: MotionCeremonyEventKind): boolean => pendingKind !== kind
      );
    });
  }

  static emit(kind: MotionCeremonyEventKind): boolean {
    let handled: boolean = false;
    MotionCeremonyEventService.listeners.forEach((listener: MotionCeremonyEventListener): void => {
      handled = MotionCeremonyEventService.tryHandle(listener, kind) || handled;
    });
    if (!handled) {
      MotionCeremonyEventService.enqueue(kind);
    }
    return handled;
  }

  private static tryHandle(listener: MotionCeremonyEventListener, kind: MotionCeremonyEventKind): boolean {
    try {
      return listener(kind);
    } catch (error) {
      console.warn(`[MotionCeremonyEventService] listener failed: ${error}`);
      return false;
    }
  }
}
