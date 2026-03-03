import { env } from "../config/env.js";
import { prisma } from "../lib/prisma.js";
import type { AuthUser } from "./auth-user.js";

export async function loadAuthUser(userId: string): Promise<AuthUser | null> {
  const dbUser = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      id: true,
      name: true,
      email: true,
      role: true,
      isBanned: true,
      banReason: true,
      avatarLink: true,
    },
  });

  if (!dbUser) {
    return null;
  }

  let role = dbUser.role;
  if (dbUser.email === env.ADMIN_BOOTSTRAP_EMAIL && dbUser.role !== "ADMIN") {
    await prisma.user.update({
      where: { id: dbUser.id },
      data: { role: "ADMIN" },
    });
    role = "ADMIN";
  }

  return {
    id: dbUser.id,
    name: dbUser.name,
    email: dbUser.email,
    role,
    isBanned: dbUser.isBanned,
    banReason: dbUser.banReason,
    avatarLink: dbUser.avatarLink,
  };
}
