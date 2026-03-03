import type { AuthUser } from "../utils/auth-user.js";

declare global {
  namespace Express {
    interface Request {
      requestId: string;
      authUser?: AuthUser;
    }
  }
}

export {};
