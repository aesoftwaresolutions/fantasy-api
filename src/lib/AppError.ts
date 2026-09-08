export class AppError extends Error {
  constructor(
    public status: number,
    public error: string,
    message: string
  ) {
    super(message);
  }
}
