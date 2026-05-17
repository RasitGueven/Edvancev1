import { useState } from 'react'
import {
  EdvanceCard,
  EdvanceBadge,
  MasteryBar,
  XPBar,
  StatCard,
  AvatarInitials,
  ProgressStep,
  EmptyState,
  LoadingPulse,
  ToastBanner,
} from '@/components/edvance'

type ToastConfig = {
  type: 'success' | 'xp' | 'warning' | 'error'
  message: string
  xpAmount?: number
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="flex flex-col gap-4">
      <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--text-muted)]">
        {title}
      </h2>
      {children}
    </section>
  )
}

export function DesignShowcase() {
  const [toast, setToast] = useState<ToastConfig | null>(null)
  const [animKey, setAnimKey] = useState(0)

  function fireToast(config: ToastConfig) {
    setToast(null)
    setTimeout(() => setToast(config), 50)
  }

  return (
    <div className="min-h-full bg-[var(--background)] pb-16">
      {/* Header */}
      <div className="px-8 py-10 bg-[var(--brand-navy)]">
        <div className="max-w-5xl mx-auto">
          <EdvanceBadge variant="xp" className="mb-4">Design System v2</EdvanceBadge>
          <h1 className="text-2xl font-bold text-white mt-2">Edvance Design Showcase</h1>
          <p className="text-sm text-[var(--brand-blue-light)] mt-1 leading-relaxed max-w-lg">
            Alle Komponenten auf einen Blick – der visuelle Spiegel vor jedem Release.
            Jeder neue Screen muss mit dieser Seite konsistent sein.
          </p>
        </div>
      </div>

      <div className="px-8 py-10 flex flex-col gap-14 max-w-5xl mx-auto">

        {/* ── Typografie ── */}
        <Section title="Typografie-Hierarchie">
          <EdvanceCard>
            <div className="flex flex-col gap-5">
              <div className="flex items-baseline gap-4">
                <span className="w-40 text-xs text-[var(--text-muted)] font-mono shrink-0">text-2xl font-bold</span>
                <p className="text-2xl font-bold text-[var(--text-primary)]">Screen-Titel</p>
              </div>
              <div className="h-px bg-[var(--border)]" />
              <div className="flex items-baseline gap-4">
                <span className="w-40 text-xs text-[var(--text-muted)] font-mono shrink-0">text-xs uppercase</span>
                <p className="text-xs font-semibold uppercase tracking-widest text-[var(--text-muted)]">Section-Header</p>
              </div>
              <div className="h-px bg-[var(--border)]" />
              <div className="flex items-baseline gap-4">
                <span className="w-40 text-xs text-[var(--text-muted)] font-mono shrink-0">text-base font-semibold</span>
                <p className="text-base font-semibold text-[var(--text-primary)]">Card-Titel</p>
              </div>
              <div className="h-px bg-[var(--border)]" />
              <div className="flex items-baseline gap-4">
                <span className="w-40 text-xs text-[var(--text-muted)] font-mono shrink-0">text-sm leading-relaxed</span>
                <p className="text-sm leading-relaxed text-[var(--text-secondary)]">Body-Text – fließend, gut lesbar, nie zu eng gesetzt.</p>
              </div>
              <div className="h-px bg-[var(--border)]" />
              <div className="flex items-baseline gap-4">
                <span className="w-40 text-xs text-[var(--text-muted)] font-mono shrink-0">text-3xl font-bold</span>
                <p className="text-3xl font-bold text-[var(--primary)]">92%</p>
              </div>
              <div className="h-px bg-[var(--border)]" />
              <div className="flex items-baseline gap-4">
                <span className="w-40 text-xs text-[var(--text-muted)] font-mono shrink-0">text-xs</span>
                <p className="text-xs text-[var(--text-muted)]">Caption – Zeitstempel, Metadaten, sekundäre Info</p>
              </div>
            </div>
          </EdvanceCard>
        </Section>

        {/* ── Schatten & Elevation ── */}
        <Section title="Schatten & Elevation">
          <div className="grid grid-cols-4 gap-4">
            {[
              { label: 'shadow-card',        cls: 'shadow-card',         desc: 'Standard Cards' },
              { label: 'shadow-elevation-sm', cls: 'shadow-elevation-sm', desc: 'Hover-Zustand' },
              { label: 'shadow-elevation-md', cls: 'shadow-elevation-md', desc: 'Raised Cards' },
              { label: 'shadow-elevation-lg', cls: 'shadow-elevation-lg', desc: 'Toasts, Modals' },
            ].map(({ label, cls, desc }) => (
              <div
                key={label}
                className={`bg-[var(--surface)] rounded-[var(--radius-xl)] p-5 border border-[var(--border)] ${cls}`}
              >
                <p className="text-xs font-mono font-semibold text-[var(--text-primary)] mb-1">{label}</p>
                <p className="text-xs text-[var(--text-muted)]">{desc}</p>
              </div>
            ))}
          </div>
        </Section>

        {/* ── Farb-Tokens ── */}
        <Section title="Design Tokens – Farben">
          <div className="grid grid-cols-2 gap-4">
            {[
              { group: 'Brand',
                tokens: [
                  { label: 'Brand Navy',    var: '--brand-navy' },
                  { label: 'Primary',       var: '--primary' },
                  { label: 'Primary Light', var: '--primary-light' },
                  { label: 'Primary Pale',  var: '--primary-pale' },
                ]
              },
              { group: 'Status',
                tokens: [
                  { label: 'Success',     var: '--success' },
                  { label: 'Warning',     var: '--warning' },
                  { label: 'Destructive', var: '--destructive' },
                  { label: 'Info',        var: '--info' },
                ]
              },
              { group: 'Gamification',
                tokens: [
                  { label: 'XP Gold (=Accent)', var: '--xp-gold' },
                  { label: 'XP Gold Light',     var: '--xp-gold-light' },
                  { label: 'Streak Orange',     var: '--streak-orange' },
                ]
              },
              { group: 'Emotionale Momente',
                tokens: [
                  { label: 'Level-Up',        var: '--color-levelup' },
                  { label: 'Level-Up Moment', var: '--color-moment-levelup' },
                  { label: 'Repair (Lila)',   var: '--color-moment-repair' },
                  { label: 'Erfolg/Boss',     var: '--color-moment-green' },
                  { label: 'Streak-Verlust',  var: '--color-moment-red' },
                  { label: 'Moment-Bühne',    var: '--color-moment-bg' },
                ]
              },
              { group: 'Text & Surface',
                tokens: [
                  { label: 'Text Primary',   var: '--text-primary' },
                  { label: 'Text Secondary', var: '--text-secondary' },
                  { label: 'Text Muted',     var: '--text-muted' },
                  { label: 'Surface',        var: '--surface' },
                ]
              },
            ].map(({ group, tokens }) => (
              <EdvanceCard key={group}>
                <p className="text-xs font-semibold uppercase tracking-widest text-[var(--text-muted)] mb-4">
                  {group}
                </p>
                <div className="flex flex-col gap-3">
                  {tokens.map(({ label, var: cssVar }) => (
                    <div key={cssVar} className="flex items-center gap-3">
                      <div
                        className="w-8 h-8 rounded-[var(--radius-sm)] flex-none border border-[var(--border)]"
                        style={{ backgroundColor: `var(${cssVar})` }}
                      />
                      <span className="text-sm font-semibold text-[var(--text-primary)] flex-1">{label}</span>
                      <code className="text-xs text-[var(--text-muted)] font-mono">{cssVar}</code>
                    </div>
                  ))}
                </div>
              </EdvanceCard>
            ))}
          </div>
        </Section>

        {/* ── Spacing ── */}
        <Section title="Spacing-Rhythmus (4pt Grid)">
          <EdvanceCard>
            <div className="flex flex-col gap-3">
              {[
                { token: '--space-1',  px: '4px',  label: 'space-1' },
                { token: '--space-2',  px: '8px',  label: 'space-2' },
                { token: '--space-4',  px: '16px', label: 'space-4' },
                { token: '--space-6',  px: '24px', label: 'space-6' },
                { token: '--space-8',  px: '32px', label: 'space-8' },
                { token: '--space-12', px: '48px', label: 'space-12' },
                { token: '--space-16', px: '64px', label: 'space-16' },
              ].map(({ token, px, label }) => (
                <div key={token} className="flex items-center gap-4">
                  <code className="text-xs font-mono text-[var(--text-muted)] w-24 shrink-0">{label}</code>
                  <div
                    className="h-5 rounded bg-[var(--primary-pale)] border border-[var(--primary-light)]"
                    style={{ width: px }}
                  />
                  <span className="text-xs text-[var(--text-muted)]">{px}</span>
                </div>
              ))}
            </div>
          </EdvanceCard>
        </Section>

        {/* ── EdvanceCard Varianten ── */}
        <Section title="EdvanceCard – Varianten & Accents">
          <div className="grid grid-cols-2 gap-4">
            <EdvanceCard variant="default">
              <p className="text-xs font-semibold uppercase tracking-wider text-[var(--text-muted)] mb-2">variant: default</p>
              <p className="text-sm text-[var(--text-secondary)] leading-relaxed">
                Standard-Card mit weißem Hintergrund. Für den meisten Content.
              </p>
            </EdvanceCard>

            <EdvanceCard variant="raised">
              <p className="text-xs font-semibold uppercase tracking-wider text-[var(--text-muted)] mb-2">variant: raised</p>
              <p className="text-sm text-[var(--text-secondary)] leading-relaxed">
                Erhöhte Card für prominenteren Content.
              </p>
            </EdvanceCard>

            <EdvanceCard variant="navy">
              <p className="text-xs font-semibold uppercase tracking-wider opacity-60 mb-2">variant: navy</p>
              <p className="text-sm leading-relaxed opacity-80">
                Navy-Hintergrund. Für Header-Bereiche oder primäre Highlights.
              </p>
            </EdvanceCard>

            <EdvanceCard variant="blue-pale">
              <p className="text-xs font-semibold uppercase tracking-wider text-[var(--text-muted)] mb-2">variant: blue-pale</p>
              <p className="text-sm text-[var(--text-secondary)] leading-relaxed">
                Helles Blau. Für Info-Boxen oder Onboarding-Hinweise.
              </p>
            </EdvanceCard>
          </div>

          <div className="grid grid-cols-2 gap-4">
            {(['left-primary', 'left-success', 'left-warning', 'left-destructive'] as const).map(
              (accent) => (
                <EdvanceCard key={accent} accent={accent}>
                  <p className="text-xs font-semibold uppercase tracking-wider text-[var(--text-muted)] mb-1">
                    accent: {accent}
                  </p>
                  <p className="text-sm text-[var(--text-secondary)]">Farbiger linker Rand für Status-Indikation.</p>
                </EdvanceCard>
              ),
            )}
          </div>
        </Section>

        {/* ── EdvanceBadge ── */}
        <Section title="EdvanceBadge – alle Varianten">
          <EdvanceCard>
            <div className="flex flex-wrap gap-3">
              <EdvanceBadge variant="primary">Primary</EdvanceBadge>
              <EdvanceBadge variant="success">Erfolg</EdvanceBadge>
              <EdvanceBadge variant="warning">Hinweis</EdvanceBadge>
              <EdvanceBadge variant="destructive">Fehler</EdvanceBadge>
              <EdvanceBadge variant="muted">Neutral</EdvanceBadge>
              <EdvanceBadge variant="xp">1.240 XP</EdvanceBadge>
              <EdvanceBadge variant="streak">14 Tage</EdvanceBadge>
            </div>
          </EdvanceCard>
        </Section>

        {/* ── MasteryBar ── */}
        <Section title="MasteryBar – Level 1–10">
          <EdvanceCard>
            <div className="flex flex-col gap-5">
              {[1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map((lvl) => (
                <MasteryBar key={lvl} level={lvl} showLabel size="md" />
              ))}
            </div>
          </EdvanceCard>
          <div className="grid grid-cols-3 gap-4">
            {(['sm', 'md', 'lg'] as const).map((size) => (
              <EdvanceCard key={size}>
                <p className="text-xs text-[var(--text-muted)] mb-3 font-semibold uppercase tracking-wider">size: {size}</p>
                <MasteryBar level={7} size={size} />
              </EdvanceCard>
            ))}
          </div>
        </Section>

        {/* ── XPBar ── */}
        <Section title="XPBar – Shimmer-Animation">
          <EdvanceCard>
            <div className="flex flex-col gap-6">
              <XPBar current={840} max={1000} level={7}  levelName="Fortgeschrittener" />
              <XPBar current={120} max={500}  level={2}  levelName="Anfänger" />
              <XPBar current={480} max={480}  level={12} levelName="Meister" />
            </div>
          </EdvanceCard>
        </Section>

        {/* ── StatCard ── */}
        <Section title="StatCard – Hover-Lift-Effekt">
          <div className="grid grid-cols-3 gap-4">
            <StatCard value="92%"   label="Aufgaben abgeschlossen" icon="✅" trend="+8%"  color="var(--success)" />
            <StatCard value="14"    label="Tage Streak aktiv"      icon="🔥" trend="+3"   color="var(--streak-orange)" />
            <StatCard value="3.240" label="XP diese Woche"         icon="⚡" trend="+12%" color="var(--xp-gold)" />
            <StatCard value="2"     label="Offene Aufgaben"        icon="📋" trend="-1"   color="var(--warning)" />
            <StatCard value="18"    label="Aktive Schüler"         icon="👥"              color="var(--primary)" />
            <StatCard value="4.8"   label="Coach-Bewertung"        icon="⭐" trend="+0.2" color="var(--level-purple)" />
          </div>
        </Section>

        {/* ── AvatarInitials ── */}
        <Section title="AvatarInitials – Auto-Farbe aus Name">
          <EdvanceCard>
            <div className="flex flex-col gap-6">
              <div>
                <p className="text-xs text-[var(--text-muted)] mb-3 font-semibold uppercase tracking-wider">Größen</p>
                <div className="flex items-end gap-4">
                  <AvatarInitials name="Maria Schmidt" size="sm" />
                  <AvatarInitials name="Maria Schmidt" size="md" />
                  <AvatarInitials name="Maria Schmidt" size="lg" />
                </div>
              </div>
              <div>
                <p className="text-xs text-[var(--text-muted)] mb-3 font-semibold uppercase tracking-wider">
                  Konsistente Hash-Farbe aus Namen
                </p>
                <div className="flex gap-4 flex-wrap">
                  {['Anna Müller', 'Jonas Weber', 'Lena Fischer', 'Max Bauer', 'Sophie Klein', 'Tim Schulz'].map(
                    (name) => (
                      <div key={name} className="flex flex-col items-center gap-1.5">
                        <AvatarInitials name={name} />
                        <span className="text-xs text-[var(--text-muted)] text-center max-w-[48px] leading-tight">
                          {name.split(' ')[0]}
                        </span>
                      </div>
                    ),
                  )}
                </div>
              </div>
            </div>
          </EdvanceCard>
        </Section>

        {/* ── ProgressStep ── */}
        <Section title="ProgressStep – Onboarding-Stepper">
          <EdvanceCard>
            <div className="flex flex-col gap-8">
              <ProgressStep steps={['Profil', 'Fächer', 'Ziele', 'Abschluss']} current={0} />
              <ProgressStep steps={['Profil', 'Fächer', 'Ziele', 'Abschluss']} current={2} />
              <ProgressStep steps={['Profil', 'Fächer', 'Ziele', 'Abschluss']} current={4} />
            </div>
          </EdvanceCard>
        </Section>

        {/* ── EmptyState ── */}
        <Section title="EmptyState – einladende Leerzustände">
          <div className="grid grid-cols-2 gap-4">
            <EdvanceCard>
              <EmptyState
                icon="📚"
                title="Noch keine Aufgaben"
                description="Dein Coach hat noch keine Aufgaben erstellt. Schau morgen wieder rein."
                action={
                  <button
                    className="px-4 py-2 rounded-[var(--radius-lg)] text-sm font-semibold bg-[var(--primary)] text-white min-h-[44px]"
                  >
                    Aufgaben anfragen
                  </button>
                }
              />
            </EdvanceCard>
            <EdvanceCard>
              <EmptyState
                icon="🏆"
                title="Noch keine Erfolge"
                description="Schließe deine erste Aufgabe ab, um hier Abzeichen zu sammeln."
              />
            </EdvanceCard>
          </div>
        </Section>

        {/* ── LoadingPulse ── */}
        <Section title="LoadingPulse – Skeleton-Loader">
          <div className="flex flex-col gap-4">
            <div>
              <p className="text-xs text-[var(--text-muted)] mb-3 font-semibold uppercase tracking-wider">type: list</p>
              <EdvanceCard><LoadingPulse type="list" lines={4} /></EdvanceCard>
            </div>
            <div>
              <p className="text-xs text-[var(--text-muted)] mb-3 font-semibold uppercase tracking-wider">type: card</p>
              <LoadingPulse type="card" />
            </div>
            <div>
              <p className="text-xs text-[var(--text-muted)] mb-3 font-semibold uppercase tracking-wider">type: stat</p>
              <LoadingPulse type="stat" />
            </div>
          </div>
        </Section>

        {/* ── Animationen ── */}
        <Section title="Animationen – Demo">
          <EdvanceCard>
            <p className="text-sm text-[var(--text-secondary)] leading-relaxed mb-5">
              Klicke auf einen Button um die Animation einmalig zu triggern.
            </p>
            <div className="flex flex-wrap items-center gap-6">
              {[
                { label: 'bounce-pop',   cls: 'animate-bounce-pop' },
                { label: 'scale-in',     cls: 'animate-scale-in' },
                { label: 'fade-in',      cls: 'animate-fade-in' },
                { label: 'xp-pulse',     cls: 'animate-xp-pulse' },
              ].map(({ label, cls }) => (
                <div key={label} className="flex flex-col items-center gap-3">
                  <div
                    key={`${label}-${animKey}`}
                    className={`w-12 h-12 rounded-[var(--radius-lg)] bg-[var(--primary)] flex items-center justify-center text-white text-lg ${animKey > 0 ? cls : ''}`}
                  >
                    ⚡
                  </div>
                  <button
                    className="text-xs font-mono text-[var(--primary)] underline"
                    onClick={() => setAnimKey((k) => k + 1)}
                  >
                    .{label}
                  </button>
                </div>
              ))}
            </div>
          </EdvanceCard>
        </Section>

        {/* ── ToastBanner Demo ── */}
        <Section title="ToastBanner – alle Typen">
          <EdvanceCard>
            <p className="text-sm text-[var(--text-secondary)] leading-relaxed mb-4">
              Erscheint oben-mittig, verschwindet nach 3s. XP-Toast feiert mit Bounce-Animation.
            </p>
            <div className="flex flex-wrap gap-3">
              <button
                onClick={() => fireToast({ type: 'xp', message: 'Aufgabe abgeschlossen!', xpAmount: 150 })}
                className="px-4 py-2 rounded-[var(--radius-lg)] text-sm font-semibold text-[var(--brand-navy)] bg-[var(--xp-gold)] min-h-[44px]"
              >
                🎉 XP Toast
              </button>
              <button
                onClick={() => fireToast({ type: 'success', message: 'Gespeichert!' })}
                className="px-4 py-2 rounded-[var(--radius-lg)] text-sm font-semibold text-white bg-[var(--success)] min-h-[44px]"
              >
                ✓ Erfolg
              </button>
              <button
                onClick={() => fireToast({ type: 'warning', message: 'Bitte vervollständige dein Profil.' })}
                className="px-4 py-2 rounded-[var(--radius-lg)] text-sm font-semibold text-[var(--warning)] bg-[var(--warning-light)] min-h-[44px]"
              >
                ⚠️ Warnung
              </button>
              <button
                onClick={() => fireToast({ type: 'error', message: 'Etwas ist schiefgelaufen.' })}
                className="px-4 py-2 rounded-[var(--radius-lg)] text-sm font-semibold text-white bg-[var(--destructive)] min-h-[44px]"
              >
                ✕ Fehler
              </button>
            </div>
          </EdvanceCard>
        </Section>

      </div>

      {toast && (
        <ToastBanner
          type={toast.type}
          message={toast.message}
          xpAmount={toast.xpAmount}
          onClose={() => setToast(null)}
        />
      )}
    </div>
  )
}
