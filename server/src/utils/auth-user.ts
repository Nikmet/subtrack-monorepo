export type AuthUser = {
  id: string;
  email: string;
  name: string;
  role: "USER" | "ADMIN";
  isBanned: boolean;
  banReason: string | null;
  avatarLink: string | null;
};
