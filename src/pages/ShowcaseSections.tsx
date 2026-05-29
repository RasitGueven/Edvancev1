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
} from '@/components/edvance'

export function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="flex flex-col gap-4">
      <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
        {title}
      </h2>
      {children}
    </section>
  )
}

export function TypografieSection() {
  return (
    <Section title="Typografie-Hierarchie">
      <EdvanceCard>
        <div className="flex flex-col gap-5">
          <div className="flex items-baseline gap-4">
            <span className="w-40 text-xs text-[var(--color-text-tertiary)] font-mono shrink-0">text-2xl font-bold</span>
            <p className="text-2xl font-bold text-[var(--color-text-primary)]">Screen-Titel</p>
          </div>
          <div className="h-px bg-[var(--color-border)]" />
          <div className="flex items-baseline gap-4">
            <span className="w-40 text-xs text-[var(--color-text-tertiary)] font-mono shrink-0">text-xs uppercase</span>
            <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">Section-Header</p>
          </div>
          <div className="h-px bg-[var(--color-border)]" />
          <div className="flex items-baseline gap-4">
            <span className="w-40 text-xs text-[var(--color-text-tertiary)] font-mono shrink-0">text-base font-semibold</span>
            <p className="text-base font-semibold text-[var(--color-text-primary)]">Card-Titel</p>
          </div>
          <div className="h-px bg-[var(--color-border)]" />
          <div className="flex items-baseline gap-4">
            <span className="w-40 text-xs text-[var(--color-text-tertiary)] font-mono shrink-0">text-sm leading-relaxed</span>
            <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">Body-Text – fließend, gut lesbar, nie zu eng gesetzt.</p>
          </div>
          <div className="h-px bg-[var(--color-border)]" />
          <div className="flex items-baseline gap-4">
            <span className="w-40 text-xs text-[var(--color-text-tertiary)] font-mono shrink-0">text-3xl font-bold</span>
            <p className="text-3xl font-bold text-[var(--color-primary)]">92%</p>
          </div>
          <div className="h-px bg-[var(--color-border)]" />
          <div className="flex items-baseline gap-4">
            <span className="w-40 text-xs text-[var(--color-text-tertiary)] font-mono shrink-0">text-xs</span>
            <p className="text-xs text-[var(--color-text-tertiary)]">Caption – Zeitstempel, Metadaten, sekundäre Info</p>
          </div>
        </div>
      </EdvanceCard>
    </Section>
  )
}

export function SchattenSection() {
  return (
    <Section title="Schatten & Elevation">
      <div className="grid grid-cols-4 gap-4">
        {[
          { label: 'shadow-card',        cls: 'shadow-card',         desc: 'Standard Cards' },
          { label: 'shadow-xs', cls: 'shadow-xs', desc: 'Hover-Zustand' },
          { label: 'shadow-md', cls: 'shadow-md', desc: 'Raised Cards' },
          { label: 'shadow-lg', cls: 'shadow-lg', desc: 'Toasts, Modals' },
        ].map(({ label, cls, desc }) => (
          <div
            key={label}
            className={`bg-[var(--color-bg-surface)] rounded-[var(--radius-xl)] p-5 border border-[var(--color-border)] ${cls}`}
          >
            <p className="text-xs font-mono font-semibold text-[var(--color-text-primary)] mb-1">{label}</p>
            <p className="text-xs text-[var(--color-text-tertiary)]">{desc}</p>
          </div>
        ))}
      </div>
    </Section>
  )
}

const COLOR_GROUPS = [
  { group: 'Brand', tokens: [
    { label: 'Brand Navy',    var: '--brand-navy' },
    { label: 'Primary',       var: '--primary' },
    { label: 'Primary Light', var: '--primary-light' },
    { label: 'Primary Pale',  var: '--primary-pale' },
  ]},
  { group: 'Status', tokens: [
    { label: 'Success',     var: '--success' },
    { label: 'Warning',     var: '--warning' },
    { label: 'Destructive', var: '--destructive' },
    { label: 'Info',        var: '--info' },
  ]},
  { group: 'Gamification', tokens: [
    { label: 'XP Gold (=Accent)', var: '--xp-gold' },
    { label: 'XP Gold Light',     var: '--xp-gold-light' },
    { label: 'Streak Orange',     var: '--streak-orange' },
  ]},
  { group: 'Emotionale Momente', tokens: [
    { label: 'Level-Up',        var: '--color-levelup' },
    { label: 'Level-Up Moment', var: '--color-moment-levelup' },
    { label: 'Repair (Lila)',   var: '--color-moment-repair' },
    { label: 'Erfolg/Boss',     var: '--color-moment-green' },
    { label: 'Streak-Verlust',  var: '--color-moment-red' },
    { label: 'Moment-Bühne',    var: '--color-moment-bg' },
  ]},
  { group: 'Text & Surface', tokens: [
    { label: 'Text Primary',   var: '--text-primary' },
    { label: 'Text Secondary', var: '--text-secondary' },
    { label: 'Text Muted',     var: '--text-muted' },
    { label: 'Surface',        var: '--surface' },
  ]},
]

export function FarbTokensSection() {
  return (
    <Section title="Design Tokens – Farben">
      <div className="grid grid-cols-2 gap-4">
        {COLOR_GROUPS.map(({ group, tokens }) => (
          <EdvanceCard key={group}>
            <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)] mb-4">
              {group}
            </p>
            <div className="flex flex-col gap-3">
              {tokens.map(({ label, var: cssVar }) => (
                <div key={cssVar} className="flex items-center gap-3">
                  <div
                    className="w-8 h-8 rounded-[var(--radius-sm)] flex-none border border-[var(--color-border)]"
                    style={{ backgroundColor: `var(${cssVar})` }}
                  />
                  <span className="text-sm font-semibold text-[var(--color-text-primary)] flex-1">{label}</span>
                  <code className="text-xs text-[var(--color-text-tertiary)] font-mono">{cssVar}</code>
                </div>
              ))}
            </div>
          </EdvanceCard>
        ))}
      </div>
    </Section>
  )
}

const SPACING_TOKENS = [
  { token: '--space-1',  px: '4px',  label: 'space-1' },
  { token: '--space-2',  px: '8px',  label: 'space-2' },
  { token: '--space-4',  px: '16px', label: 'space-4' },
  { token: '--space-6',  px: '24px', label: 'space-6' },
  { token: '--space-8',  px: '32px', label: 'space-8' },
  { token: '--space-12', px: '48px', label: 'space-12' },
  { token: '--space-16', px: '64px', label: 'space-16' },
]

export function SpacingSection() {
  return (
    <Section title="Spacing-Rhythmus (4pt Grid)">
      <EdvanceCard>
        <div className="flex flex-col gap-3">
          {SPACING_TOKENS.map(({ token, px, label }) => (
            <div key={token} className="flex items-center gap-4">
              <code className="text-xs font-mono text-[var(--color-text-tertiary)] w-24 shrink-0">{label}</code>
              <div
                className="h-5 rounded bg-[var(--color-primary-light)] border border-[var(--color-primary-light)]"
                style={{ width: px }}
              />
              <span className="text-xs text-[var(--color-text-tertiary)]">{px}</span>
            </div>
          ))}
        </div>
      </EdvanceCard>
    </Section>
  )
}

export function EdvanceCardSection() {
  return (
    <Section title="EdvanceCard – Varianten & Accents">
      <div className="grid grid-cols-2 gap-4">
        <EdvanceCard variant="default">
          <p className="text-xs font-semibold uppercase tracking-wider text-[var(--color-text-tertiary)] mb-2">variant: default</p>
          <p className="text-sm text-[var(--color-text-secondary)] leading-relaxed">
            Standard-Card mit weißem Hintergrund. Für den meisten Content.
          </p>
        </EdvanceCard>
        <EdvanceCard variant="default">
          <p className="text-xs font-semibold uppercase tracking-wider text-[var(--color-text-tertiary)] mb-2">variant: raised</p>
          <p className="text-sm text-[var(--color-text-secondary)] leading-relaxed">
            Erhöhte Card für prominenteren Content.
          </p>
        </EdvanceCard>
        <EdvanceCard variant="hero-student">
          <p className="text-xs font-semibold uppercase tracking-wider opacity-60 mb-2">variant: navy</p>
          <p className="text-sm leading-relaxed opacity-80">
            Navy-Hintergrund. Für Header-Bereiche oder primäre Highlights.
          </p>
        </EdvanceCard>
        <EdvanceCard variant="subtle">
          <p className="text-xs font-semibold uppercase tracking-wider text-[var(--color-text-tertiary)] mb-2">variant: blue-pale</p>
          <p className="text-sm text-[var(--color-text-secondary)] leading-relaxed">
            Helles Blau. Für Info-Boxen oder Onboarding-Hinweise.
          </p>
        </EdvanceCard>
      </div>
      <div className="grid grid-cols-2 gap-4">
        {(['left-primary', 'left-success', 'left-warning', 'left-destructive'] as const).map((accent) => (
          <EdvanceCard key={accent} accent={accent}>
            <p className="text-xs font-semibold uppercase tracking-wider text-[var(--color-text-tertiary)] mb-1">
              accent: {accent}
            </p>
            <p className="text-sm text-[var(--color-text-secondary)]">Farbiger linker Rand für Status-Indikation.</p>
          </EdvanceCard>
        ))}
      </div>
    </Section>
  )
}

export function BadgeSection() {
  return (
    <Section title="EdvanceBadge – alle Varianten">
      <EdvanceCard>
        <div className="flex flex-wrap gap-3">
          <EdvanceBadge variant="primary">Primary</EdvanceBadge>
          <EdvanceBadge variant="mastered">Erfolg</EdvanceBadge>
          <EdvanceBadge variant="warning">Hinweis</EdvanceBadge>
          <EdvanceBadge variant="exam">Fehler</EdvanceBadge>
          <EdvanceBadge variant="muted">Neutral</EdvanceBadge>
          <EdvanceBadge variant="xp-day">1.240 XP</EdvanceBadge>
          <EdvanceBadge variant="streak-presence">14 Tage</EdvanceBadge>
        </div>
      </EdvanceCard>
    </Section>
  )
}

export function MasteryBarSection() {
  return (
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
            <p className="text-xs text-[var(--color-text-tertiary)] mb-3 font-semibold uppercase tracking-wider">size: {size}</p>
            <MasteryBar level={7} size={size} />
          </EdvanceCard>
        ))}
      </div>
    </Section>
  )
}

export function XPBarSection() {
  return (
    <Section title="XPBar – Shimmer-Animation">
      <EdvanceCard>
        <div className="flex flex-col gap-6">
          <XPBar current={840} max={1000} level={7}  levelName="Fortgeschrittener" />
          <XPBar current={120} max={500}  level={2}  levelName="Anfänger" />
          <XPBar current={480} max={480}  level={12} levelName="Meister" />
        </div>
      </EdvanceCard>
    </Section>
  )
}

export function StatCardSection() {
  return (
    <Section title="StatCard – Hover-Lift-Effekt">
      <div className="grid grid-cols-3 gap-4">
        <StatCard value="92%"   label="Aufgaben abgeschlossen" icon="✅" trend="+8%"  color="var(--color-success)" />
        <StatCard value="14"    label="Tage Streak aktiv"      icon="🔥" trend="+3"   color="var(--color-accent-streak)" />
        <StatCard value="3.240" label="XP diese Woche"         icon="⚡" trend="+12%" color="var(--color-accent)" />
        <StatCard value="2"     label="Offene Aufgaben"        icon="📋" trend="-1"   color="var(--color-gold-warning)" />
        <StatCard value="18"    label="Aktive Schüler"         icon="👥"              color="var(--color-primary)" />
        <StatCard value="4.8"   label="Coach-Bewertung"        icon="⭐" trend="+0.2" color="var(--color-repair)" />
      </div>
    </Section>
  )
}

export function AvatarSection() {
  return (
    <Section title="AvatarInitials – Auto-Farbe aus Name">
      <EdvanceCard>
        <div className="flex flex-col gap-6">
          <div>
            <p className="text-xs text-[var(--color-text-tertiary)] mb-3 font-semibold uppercase tracking-wider">Größen</p>
            <div className="flex items-end gap-4">
              <AvatarInitials name="Maria Schmidt" size="sm" />
              <AvatarInitials name="Maria Schmidt" size="md" />
              <AvatarInitials name="Maria Schmidt" size="lg" />
            </div>
          </div>
          <div>
            <p className="text-xs text-[var(--color-text-tertiary)] mb-3 font-semibold uppercase tracking-wider">
              Konsistente Hash-Farbe aus Namen
            </p>
            <div className="flex gap-4 flex-wrap">
              {['Anna Müller', 'Jonas Weber', 'Lena Fischer', 'Max Bauer', 'Sophie Klein', 'Tim Schulz'].map((name) => (
                <div key={name} className="flex flex-col items-center gap-1.5">
                  <AvatarInitials name={name} />
                  <span className="text-xs text-[var(--color-text-tertiary)] text-center max-w-[48px] leading-tight">
                    {name.split(' ')[0]}
                  </span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </EdvanceCard>
    </Section>
  )
}

export function ProgressStepSection() {
  return (
    <Section title="ProgressStep – Onboarding-Stepper">
      <EdvanceCard>
        <div className="flex flex-col gap-8">
          <ProgressStep steps={['Profil', 'Fächer', 'Ziele', 'Abschluss']} current={0} />
          <ProgressStep steps={['Profil', 'Fächer', 'Ziele', 'Abschluss']} current={2} />
          <ProgressStep steps={['Profil', 'Fächer', 'Ziele', 'Abschluss']} current={4} />
        </div>
      </EdvanceCard>
    </Section>
  )
}

export function EmptyStateSection() {
  return (
    <Section title="EmptyState – einladende Leerzustände">
      <div className="grid grid-cols-2 gap-4">
        <EdvanceCard>
          <EmptyState
            icon="📚"
            title="Noch keine Aufgaben"
            description="Dein Coach hat noch keine Aufgaben erstellt. Schau morgen wieder rein."
            action={
              <button className="px-4 py-2 rounded-[var(--radius-lg)] text-sm font-semibold bg-[var(--color-primary)] text-white min-h-[44px]">
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
  )
}

export function LoadingPulseSection() {
  return (
    <Section title="LoadingPulse – Skeleton-Loader">
      <div className="flex flex-col gap-4">
        <div>
          <p className="text-xs text-[var(--color-text-tertiary)] mb-3 font-semibold uppercase tracking-wider">type: list</p>
          <EdvanceCard><LoadingPulse type="list" lines={4} /></EdvanceCard>
        </div>
        <div>
          <p className="text-xs text-[var(--color-text-tertiary)] mb-3 font-semibold uppercase tracking-wider">type: card</p>
          <LoadingPulse type="card" />
        </div>
        <div>
          <p className="text-xs text-[var(--color-text-tertiary)] mb-3 font-semibold uppercase tracking-wider">type: stat</p>
          <LoadingPulse type="stat" />
        </div>
      </div>
    </Section>
  )
}
