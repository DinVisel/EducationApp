"use client";

import { useCallback, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { api, UnauthorizedError } from "@/lib/api";
import type { AdminUser, PagedResult, UserRole } from "@/lib/types";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";

const PAGE_SIZE = 25;
const ROLES: (UserRole | "")[] = ["", "Teacher", "Student", "Admin"];

export default function UsersPage() {
  const router = useRouter();
  const [data, setData] = useState<PagedResult<AdminUser> | null>(null);
  const [search, setSearch] = useState("");
  const [role, setRole] = useState<UserRole | "">("");
  const [page, setPage] = useState(1);
  const [error, setError] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<number | null>(null);

  const load = useCallback(() => {
    const params = new URLSearchParams({
      page: String(page),
      pageSize: String(PAGE_SIZE),
    });
    if (search.trim()) params.set("search", search.trim());
    if (role) params.set("role", role);

    api
      .get<PagedResult<AdminUser>>(`/admin/users?${params.toString()}`)
      .then(setData)
      .catch((err) => {
        if (err instanceof UnauthorizedError) router.replace("/login");
        else setError(err.message);
      });
  }, [page, search, role, router]);

  useEffect(() => {
    load();
  }, [load]);

  async function act(user: AdminUser, action: "ban" | "unban") {
    setBusyId(user.id);
    try {
      await api.post(`/admin/users/${user.id}/${action}`);
      load();
    } catch (err) {
      if (err instanceof UnauthorizedError) router.replace("/login");
      else setError(err instanceof Error ? err.message : "Action failed.");
    } finally {
      setBusyId(null);
    }
  }

  async function changeRole(user: AdminUser, newRole: UserRole) {
    if (newRole === user.role) return;
    setBusyId(user.id);
    try {
      await api.post(`/admin/users/${user.id}/role`, { role: newRole });
      load();
    } catch (err) {
      if (err instanceof UnauthorizedError) router.replace("/login");
      else setError(err instanceof Error ? err.message : "Action failed.");
    } finally {
      setBusyId(null);
    }
  }

  const totalPages = data ? Math.max(1, Math.ceil(data.total / PAGE_SIZE)) : 1;

  return (
    <div className="space-y-4">
      <h1 className="text-xl font-semibold">Users</h1>

      <div className="flex flex-wrap gap-2">
        <Input
          placeholder="Search email or name…"
          value={search}
          onChange={(e) => {
            setPage(1);
            setSearch(e.target.value);
          }}
          className="max-w-xs"
        />
        <select
          value={role}
          onChange={(e) => {
            setPage(1);
            setRole(e.target.value as UserRole | "");
          }}
          className="h-9 rounded-md border border-input bg-transparent px-3 text-sm"
        >
          {ROLES.map((r) => (
            <option key={r} value={r}>
              {r === "" ? "All roles" : r}
            </option>
          ))}
        </select>
      </div>

      {error && <p className="text-sm text-destructive">{error}</p>}

      <div className="rounded-lg border border-border bg-card">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>ID</TableHead>
              <TableHead>Email</TableHead>
              <TableHead>Name</TableHead>
              <TableHead>Role</TableHead>
              <TableHead>Status</TableHead>
              <TableHead className="text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {data?.items.map((u) => (
              <TableRow key={u.id}>
                <TableCell className="text-muted-foreground">{u.id}</TableCell>
                <TableCell>{u.email}</TableCell>
                <TableCell>{u.name ?? "—"}</TableCell>
                <TableCell>
                  <select
                    value={u.role}
                    disabled={busyId === u.id}
                    onChange={(e) => changeRole(u, e.target.value as UserRole)}
                    className="h-7 rounded-md border border-input bg-transparent px-2 text-xs"
                  >
                    <option value="Teacher">Teacher</option>
                    <option value="Student">Student</option>
                    <option value="Admin">Admin</option>
                  </select>
                </TableCell>
                <TableCell>
                  {u.isBanned ? (
                    <Badge variant="destructive">Banned</Badge>
                  ) : (
                    <Badge variant="muted">Active</Badge>
                  )}
                </TableCell>
                <TableCell className="text-right">
                  {u.isBanned ? (
                    <Button
                      size="sm"
                      variant="outline"
                      disabled={busyId === u.id}
                      onClick={() => act(u, "unban")}
                    >
                      Unban
                    </Button>
                  ) : (
                    <Button
                      size="sm"
                      variant="destructive"
                      disabled={busyId === u.id || u.role === "Admin"}
                      onClick={() => act(u, "ban")}
                    >
                      Ban
                    </Button>
                  )}
                </TableCell>
              </TableRow>
            ))}
            {data && data.items.length === 0 && (
              <TableRow>
                <TableCell colSpan={6} className="text-center text-muted-foreground">
                  No users found.
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>

      <div className="flex items-center justify-between text-sm text-muted-foreground">
        <span>{data ? `${data.total} users` : ""}</span>
        <div className="flex items-center gap-2">
          <Button
            size="sm"
            variant="outline"
            disabled={page <= 1}
            onClick={() => setPage((p) => p - 1)}
          >
            Previous
          </Button>
          <span>
            Page {page} of {totalPages}
          </span>
          <Button
            size="sm"
            variant="outline"
            disabled={page >= totalPages}
            onClick={() => setPage((p) => p + 1)}
          >
            Next
          </Button>
        </div>
      </div>
    </div>
  );
}
