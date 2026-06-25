export class ReviewLibraryRefreshService {
  private static refreshToken: number = 0;
  private static lastReason: string = '';

  static notifyReviewLibraryChanged(reason: string): number {
    ReviewLibraryRefreshService.refreshToken += 1;
    ReviewLibraryRefreshService.lastReason = reason;
    console.info(`[ReviewLibraryRefresh] token=${ReviewLibraryRefreshService.refreshToken}, reason=${reason}`);
    return ReviewLibraryRefreshService.refreshToken;
  }

  static getRefreshToken(): number {
    return ReviewLibraryRefreshService.refreshToken;
  }

  static getLastReason(): string {
    return ReviewLibraryRefreshService.lastReason;
  }
}
