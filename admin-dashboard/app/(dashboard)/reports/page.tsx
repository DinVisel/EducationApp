"use client";

import { useCallback, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { api, UnauthorizedError } from "@/lib/api";
import type { Report } from "@/lib/types";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";

export default function ReportsPage() {
  const router = useRouter();
  const [reports, setReports] = useState<Report[]>([]);
  const [resolved, setResolved] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<number | null>(null);

  const load = useCallback(() => {
    api
      .get<Report[]>(`/admin/reports?resolved=${resolved}`)
      .then(setReports)
      .catch((err) => {
        if (err instanceof UnauthorizedError) router.replace("/login");
        else setError(err.message);
      });
  }, [resolved, router]);

  useEffect(() => {
    load();
  }, [load]);

  async function act(id: number, action: "dismiss" | "remove") {
    setBusyId(id);
    try {
      await api.post(`/admin/reports/${id}/${action}`);
      load();
    } catch (err) {
      if (err instanceof UnauthorizedError) router.replace("/login");
      else setError(err instanceof Error ? err.message : "Action failed.");
    } finally {
      setBusyId(null);
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-semibold">Reports</h1>
        <div className="flex gap-1">
          <Button
            size="sm"
            variant={resolved ? "outline" : "default"}
            onClick={() => setResolved(false)}
          >
            Open
          </Button>
          <Button
            size="sm"
            variant={resolved ? "default" : "outline"}
            onClick={() => setResolved(true)}
          >
            Resolved
          </Button>
        </div>
      </div>

      {error && <p className="text-sm text-destructive">{error}</p>}

      {reports.length === 0 ? (
        <p className="text-sm text-muted-foreground">
          No {resolved ? "resolved" : "open"} reports.
        </p>
      ) : (
        <div className="space-y-3">
          {reports.map((r) => (
            <Card key={r.id}>
              <CardContent className="pt-5">
                <div className="flex items-start justify-between gap-4">
                  <div className="space-y-1">
                    <div className="flex items-center gap-2">
                      <Badge variant="outline">{r.targetType}</Badge>
                      <span className="text-sm font-medium">{r.reason}</span>
                    </div>
                    <p className="text-sm text-muted-foreground">
                      {r.targetText ?? <em>content removed</em>}
                    </p>
                    <p className="text-xs text-muted-foreground">
                      Author: {r.targetAuthorName ?? "—"} · Reported by{" "}
                      {r.reporterName} · {new Date(r.createdAt).toLocaleString()}
                    </p>
                    {r.isResolved && r.resolution && (
                      <Badge variant="muted">{r.resolution}</Badge>
                    )}
                  </div>
                  {!r.isResolved && (
                    <div className="flex shrink-0 gap-2">
                      <Button
                        size="sm"
                        variant="outline"
                        disabled={busyId === r.id}
                        onClick={() => act(r.id, "dismiss")}
                      >
                        Dismiss
                      </Button>
                      <Button
                        size="sm"
                        variant="destructive"
                        disabled={busyId === r.id}
                        onClick={() => act(r.id, "remove")}
                      >
                        Remove content
                      </Button>
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
