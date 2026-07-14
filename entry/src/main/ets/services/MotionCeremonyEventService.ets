export enum MotionCeremonyEventKind {
  REVIEW_QUEUE_CLEARED = 'review-queue-cleared',
  STREAK_RECORD = 'streak-record',
  SMB_FIRST_CONNECT = 'smb-first-connect'
}

type MotionCeremonyEventListener = (kind: MotionCeremonyEventKind) => boolean;

interface MotionCeremonyPendingEvent {
  kind: MotionCeremonyEventKind;
  enqueuedAt: number;
}

const MOTION_CEREMONY_PENDING_TTL_MS: number = 60_000;

// 约束：每种 MotionCeremonyEventKind 只应有唯一订阅方。emit 返回的 handled 语义是
// “该 kind 的唯一订阅方是否接住了这次事件”；不支持多方共同消费。
// 使用契约（v2 之后）：
//   - emit(kind)：发一次事件；若无订阅方 handled，则自动入队等待下次订阅消费。
//     用于“订阅方可能已在场，也可能没在场”的通用场景。
//   - enqueue(kind)：直接入队，不尝试即时派发。用于明确知道订阅方需要切换页面后
//     才能接收的场景，例如 REVIEW_QUEUE_CLEARED 在 EditorPage 触发、由 HomePage 消费。
//   - consumePending(listener)：subscribe 内部会自动调用，不建议业务层直接调用。
export class MotionCeremonyEventService {
  private static listeners: Array<MotionCeremonyEventListener> = [];
  private static pendingKinds: Array<MotionCeremonyPendingEvent> = [];

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
    MotionCeremonyEventService.pendingKinds = MotionCeremonyEventService.pendingKinds.filter(
      (pendingEvent: MotionCeremonyPendingEvent): boolean => pendingEvent.kind !== kind
    );
    MotionCeremonyEventService.pendingKinds.push({
      kind: kind,
      enqueuedAt: Date.now()
    });
  }

  static consumePending(listener: MotionCeremonyEventListener): void {
    const now: number = Date.now();
    const pendingKinds: Array<MotionCeremonyPendingEvent> = MotionCeremonyEventService.pendingKinds.filter(
      (pendingEvent: MotionCeremonyPendingEvent): boolean =>
        now - pendingEvent.enqueuedAt <= MOTION_CEREMONY_PENDING_TTL_MS
    );
    MotionCeremonyEventService.pendingKinds = pendingKinds;
    pendingKinds.forEach((pendingEvent: MotionCeremonyPendingEvent): void => {
      if (!MotionCeremonyEventService.tryHandle(listener, pendingEvent.kind)) {
        return;
      }
      MotionCeremonyEventService.pendingKinds = MotionCeremonyEventService.pendingKinds.filter(
        (queuedEvent: MotionCeremonyPendingEvent): boolean => queuedEvent.kind !== pendingEvent.kind
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
