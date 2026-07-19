/// Mirrors of the API DTOs the dashboard consumes (see TeacherTracker.Api/Dtos).

export type UserRole = "Teacher" | "Student" | "Admin";

export interface AuthResponse {
  token: string;
  refreshToken: string;
  accessTokenExpiresAtUtc: string;
  role: UserRole;
}

export interface AdminStats {
  totalUsers: number;
  totalTeachers: number;
  totalStudents: number;
  totalAdmins: number;
  totalClassrooms: number;
  totalPosts: number;
  totalQuizzes: number;
  openReports: number;
  newUsersLast7Days: number;
  postsLast7Days: number;
}

export interface TimeSeriesPoint {
  date: string; // yyyy-MM-dd
  count: number;
}

export interface AdminOverview {
  stats: AdminStats;
  signups: TimeSeriesPoint[];
  posts: TimeSeriesPoint[];
}

export interface AdminUser {
  id: number;
  email: string;
  role: UserRole;
  name: string | null;
  createdAt: string;
  isBanned: boolean;
}

export interface PagedResult<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
}

export interface Report {
  id: number;
  reason: string;
  createdAt: string;
  reporterName: string;
  targetType: string; // "Post" | "Comment"
  targetId: number | null;
  targetText: string | null;
  targetAuthorName: string | null;
  isResolved: boolean;
  resolution: string | null;
}
