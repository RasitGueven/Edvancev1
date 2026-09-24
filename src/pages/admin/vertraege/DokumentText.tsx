import ReactMarkdown, { type Components } from 'react-markdown'

// Schlichte Typografie fuer Vertragsdokumente — auf Papier wie am Bildschirm.
// whitespace-pre-line haelt die Zeilenumbrueche der Anschrift zusammen.
const components: Components = {
  h1: ({ node: _n, ...props }) => (
    <h1 className="text-2xl font-bold text-[var(--color-text-primary)]" {...props} />
  ),
  h2: ({ node: _n, ...props }) => (
    <h2 className="mt-4 text-base font-semibold text-[var(--color-text-primary)]" {...props} />
  ),
  p: ({ node: _n, ...props }) => (
    <p className="whitespace-pre-line text-sm leading-relaxed text-[var(--color-text-primary)]" {...props} />
  ),
  ul: ({ node: _n, ...props }) => <ul className="ml-6 list-disc space-y-1 text-sm" {...props} />,
  li: ({ node: _n, ...props }) => <li className="leading-relaxed" {...props} />,
  strong: ({ node: _n, ...props }) => <strong className="font-semibold" {...props} />,
  blockquote: ({ node: _n, ...props }) => (
    <blockquote
      className="rounded-xl border border-[var(--color-gold-warning)] bg-[var(--color-gold-warning-light)] px-4 py-2 text-sm"
      {...props}
    />
  ),
  code: ({ node: _n, ...props }) => <code className="text-xs" {...props} />,
}

export function DokumentText({ text }: { text: string }): JSX.Element {
  return (
    <div className="flex flex-col gap-2">
      <ReactMarkdown components={components}>{text}</ReactMarkdown>
    </div>
  )
}
