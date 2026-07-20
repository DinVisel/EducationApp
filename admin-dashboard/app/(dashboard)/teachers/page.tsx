"use client";

import { useCallback, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
  Legend,
} from "recharts";
import { api, UnauthorizedError } from "@/lib/api";
import type { TeacherStats } from "@/lib/types";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";

// Brand-neutral categorical palette (distinct hues, similar saturation/lightness
// so no slice reads as "more important"). Reused across the pies below.
const CATEGORY_COLORS = [
  "hsl(222 47% 45%)",
  "hsl(160 55% 40%)",
  "hsl(28 80% 52%)",
  "hsl(280 45% 55%)",
  "hsl(340 60% 55%)",
];

// School-type / education-level enum values arrive as their C# names; show them
// as human-readable labels.
const LABELS: Record<string, string> = {
  State: "State",
  Private: "Private",
  Other: "Other",
  PrimarySchool: "Primary school",
  MiddleSchool: "Middle school",
  Both: "Both",
};
const pretty = (raw: string) => LABELS[raw] ?? raw;

export default function TeachersPage() {
  const router = useRouter();
  const [data, setData] = useState<TeacherStats | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [selectedCity, setSelectedCity] = useState<string | null>(null);

  const load = useCallback(
    (city: string | null) => {
      const path = city
        ? `/admin/teachers/stats?city=${encodeURIComponent(city)}`
        : "/admin/teachers/stats";
      api
        .get<TeacherStats>(path)
        .then(setData)
        .catch((err) => {
          if (err instanceof UnauthorizedError) router.replace("/login");
          else setError(err.message);
        });
    },
    [router],
  );

  useEffect(() => {
    load(selectedCity);
  }, [load, selectedCity]);

  if (error) return <p className="text-sm text-destructive">{error}</p>;
  if (!data) return <p className="text-sm text-muted-foreground">Loading…</p>;

  const coverage =
    data.totalTeachers > 0
      ? Math.round((data.withLocation / data.totalTeachers) * 100)
      : 0;

  const cityData = data.byCity.map((c) => ({ ...c }));
  const schoolData = data.bySchoolType.map((c) => ({ ...c, label: pretty(c.label) }));
  const levelData = data.byEducationLevel.map((c) => ({ ...c, label: pretty(c.label) }));

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-semibold">Teacher analytics</h1>
        <p className="text-sm text-muted-foreground">
          Demographic distributions for growth tracking and B2B targeting.
        </p>
      </div>

      {/* Headline KPIs */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <Kpi label="Total teachers" value={data.totalTeachers} />
        <Kpi label="Profiles with location" value={data.withLocation} />
        <Kpi label="Profile coverage" value={`${coverage}%`} />
      </div>

      {/* By city — click a bar to drill into that city's districts */}
      <Card>
        <CardHeader>
          <CardTitle>Teachers by city</CardTitle>
        </CardHeader>
        <CardContent>
          {cityData.length === 0 ? (
            <Empty />
          ) : (
            <ResponsiveContainer width="100%" height={Math.max(200, cityData.length * 34)}>
              <BarChart data={cityData} layout="vertical" margin={{ left: 12 }}>
                <CartesianGrid strokeDasharray="3 3" opacity={0.2} horizontal={false} />
                <XAxis type="number" allowDecimals={false} fontSize={11} />
                <YAxis
                  type="category"
                  dataKey="label"
                  width={110}
                  fontSize={11}
                  tickLine={false}
                />
                <Tooltip cursor={{ fill: "hsl(var(--muted))" }} />
                <Bar
                  dataKey="count"
                  radius={[0, 3, 3, 0]}
                  cursor="pointer"
                  onClick={(d: { label?: string }) =>
                    d.label && setSelectedCity(d.label === selectedCity ? null : d.label)
                  }
                >
                  {cityData.map((c) => (
                    <Cell
                      key={c.label}
                      fill={
                        c.label === selectedCity
                          ? "hsl(28 80% 52%)"
                          : "hsl(222 47% 45%)"
                      }
                    />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          )}
          <p className="mt-2 text-xs text-muted-foreground">
            Tip: click a city to see its district breakdown below.
          </p>
        </CardContent>
      </Card>

      {/* District drill-down for the selected city */}
      {selectedCity && (
        <Card>
          <CardHeader>
            <CardTitle>Districts in {selectedCity}</CardTitle>
          </CardHeader>
          <CardContent>
            {data.byDistrict.length === 0 ? (
              <Empty />
            ) : (
              <ResponsiveContainer
                width="100%"
                height={Math.max(160, data.byDistrict.length * 34)}
              >
                <BarChart data={data.byDistrict} layout="vertical" margin={{ left: 12 }}>
                  <CartesianGrid strokeDasharray="3 3" opacity={0.2} horizontal={false} />
                  <XAxis type="number" allowDecimals={false} fontSize={11} />
                  <YAxis
                    type="category"
                    dataKey="label"
                    width={110}
                    fontSize={11}
                    tickLine={false}
                  />
                  <Tooltip cursor={{ fill: "hsl(var(--muted))" }} />
                  <Bar dataKey="count" fill="hsl(28 80% 52%)" radius={[0, 3, 3, 0]} />
                </BarChart>
              </ResponsiveContainer>
            )}
          </CardContent>
        </Card>
      )}

      {/* School type & education level pies */}
      <div className="grid gap-4 lg:grid-cols-2">
        <DistributionPie title="By school type" data={schoolData} />
        <DistributionPie title="By education level" data={levelData} />
      </div>
    </div>
  );
}

function Kpi({ label, value }: { label: string; value: number | string }) {
  return (
    <Card>
      <CardHeader>
        <CardTitle>{label}</CardTitle>
      </CardHeader>
      <CardContent>
        <p className="text-2xl font-semibold">{value}</p>
      </CardContent>
    </Card>
  );
}

function DistributionPie({
  title,
  data,
}: {
  title: string;
  data: { label: string; count: number }[];
}) {
  return (
    <Card>
      <CardHeader>
        <CardTitle>{title}</CardTitle>
      </CardHeader>
      <CardContent>
        {data.length === 0 ? (
          <Empty />
        ) : (
          <ResponsiveContainer width="100%" height={240}>
            <PieChart>
              <Pie
                data={data}
                dataKey="count"
                nameKey="label"
                innerRadius={55}
                outerRadius={85}
                paddingAngle={2}
              >
                {data.map((d, i) => (
                  <Cell key={d.label} fill={CATEGORY_COLORS[i % CATEGORY_COLORS.length]} />
                ))}
              </Pie>
              <Tooltip />
              <Legend
                verticalAlign="bottom"
                iconType="circle"
                wrapperStyle={{ fontSize: 12 }}
              />
            </PieChart>
          </ResponsiveContainer>
        )}
      </CardContent>
    </Card>
  );
}

function Empty() {
  return (
    <div className="flex h-40 items-center justify-center text-sm text-muted-foreground">
      No data yet.
    </div>
  );
}
