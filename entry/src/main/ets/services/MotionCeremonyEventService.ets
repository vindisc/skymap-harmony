export enum MotionCeremonyEventKind {
  REVIEW_QUEUE_CLEARED = 'review-queue-cleared',
  STREAK_RECORD = 'streak-record',
  SMB_FIRST_CONNECT = 'smb-first-connect'
}

type MotionCeremonyEventListener = (kind: MotionCeremonyEventKind) => boolean;

export class MotionCeremonyEventService {
  private static listeners: Array<MotionCeremonyEventListener> = [];

  static subscribe(listener: MotionCeremonyEventListener): void {
    if (MotionCeremonyEventService.listeners.indexOf(listener) >= 0) {
      return;
    }
    MotionCeremonyEventService.listeners.push(listener);
  }

  static unsubscribe(listener: MotionCeremonyEventListener): void {
    MotionCeremonyEventService.listeners = MotionCeremonyEventService.listeners.filter(
      (item: MotionCeremonyEventListener): boolean => item !== listener
    );
  }

  static emit(kind: MotionCeremonyEventKind): boolean {
    let handled: boolean = false;
    MotionCeremonyEventService.listeners.forEach((listener: MotionCeremonyEventListener): void => {
      try {
        handled = listener(kind) || handled;
      } catch (error) {
        console.warn(`[MotionCeremonyEventService] listener failed: ${error}`);
      }
    });
    return handled;
  }
}
