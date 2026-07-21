/**
 * Button — Primäre Interaktionskomponente für alle Screens.
 *
 * Design-Regeln:
 * - moment-* Farben niemals als Button-Variante — nur in kurzlebigen Animationen (≤ 3 s).
 * - accent nie als primärer Button auf weißem Hintergrund (WCAG-Kontrast nicht erfüllt).
 * - Pro Screen max. 1 primary-Button (CLAUDE.md §11: ein klarer primärer CTA).
 * - Level-Up / Boss-Challenge Buttons max. 1× pro Session triggern.
 */
import * as React from 'react'
import { Slot } from '@radix-ui/react-slot'
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

const buttonVariants = cva(
  'inline-flex items-center justify-center gap-2 whitespace-nowrap font-semibold tracking-tight transition-all duration-200 outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-40 active:scale-[0.98]',
  {
    variants: {
      variant: {
        primary:   'bg-[var(--color-primary)] text-white shadow-xs hover:shadow-md hover:-translate-y-px hover:brightness-110',
        default:   'bg-[var(--color-primary)] text-white shadow-xs hover:shadow-md hover:-translate-y-px hover:brightness-110',
        secondary: 'border border-primary text-primary bg-transparent hover:bg-primary-light',
        outline:   'border border-primary text-primary bg-transparent hover:bg-primary-light',
        ghost:     'text-primary bg-transparent hover:bg-primary-light',
        destructive: 'bg-error text-white shadow-xs hover:shadow-md hover:brightness-110',
      },
      size: {
        sm:      'px-3 py-1.5 text-xs min-h-[36px] rounded-lg',
        default: 'px-4 py-2.5 text-sm min-h-[44px] rounded-xl',
        md:      'px-4 py-2.5 text-sm min-h-[44px] rounded-xl',
        lg:      'px-6 py-3   text-base min-h-[52px] rounded-xl',
        icon:    'h-11 w-11 rounded-xl',
      },
    },
    defaultVariants: {
      variant: 'primary',
      size: 'default',
    },
  },
)

function Spinner(): React.JSX.Element {
  return (
    <svg className="h-4 w-4 animate-spin" viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
    </svg>
  )
}

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean
  loading?: boolean
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, asChild = false, loading = false, disabled, children, ...props }, ref) => {
    const Comp = asChild ? Slot : 'button'
    return (
      <Comp
        ref={ref}
        disabled={disabled || loading}
        aria-busy={loading || undefined}
        className={cn(buttonVariants({ variant, size }), className)}
        {...props}
      >
        {asChild ? (
          children
        ) : (
          <>
            {loading && <Spinner />}
            {children}
          </>
        )}
      </Comp>
    )
  },
)
Button.displayName = 'Button'

export { Button, buttonVariants }
