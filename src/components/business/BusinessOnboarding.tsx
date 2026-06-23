import { useState } from 'react'
import { ChevronRight, MapPin, Sparkles, TrendingUp, Users } from 'lucide-react'
import { cn } from '@/lib/utils'

const SLIDES = [
  {
    icon: Users,
    title: 'Couples are already planning tonight',
    body: 'Your Date Genie builds full date nights — not random banner ads. When a couple searches your city and vibe, your spot can appear as a featured stop in their itinerary.',
  },
  {
    icon: MapPin,
    title: 'Intent-rich, local traffic',
    body: 'These are couples who picked cozy cocktails, live music, adventure, or a quiet dinner — and are ready to book. You reach people mid-plan, not mid-scroll.',
  },
  {
    icon: TrendingUp,
    title: 'Launch partner advantage',
    body: 'Early venues get featured placement pricing before we open self-serve ads. Join now to shape how date-night advertising works in your city.',
  },
] as const

interface BusinessOnboardingProps {
  onComplete: () => void
  className?: string
}

export function BusinessOnboarding({ onComplete, className }: BusinessOnboardingProps) {
  const [step, setStep] = useState(0)
  const slide = SLIDES[step]
  const Icon = slide.icon
  const isLast = step === SLIDES.length - 1

  return (
    <div className={cn('flex flex-col', className)}>
      <div className="flex gap-1.5 mb-6">
        {SLIDES.map((_, i) => (
          <span
            key={i}
            className={cn(
              'h-1 flex-1 rounded-full transition-colors',
              i <= step ? 'bg-primary' : 'bg-border'
            )}
          />
        ))}
      </div>

      <div className="rounded-xl border border-border bg-card/40 p-6 mb-6">
        <span className="inline-flex w-11 h-11 rounded-xl bg-primary/10 border border-primary/20 items-center justify-center mb-4">
          <Icon className="w-5 h-5 text-primary" />
        </span>
        <p className="text-xs font-semibold uppercase tracking-wider text-primary mb-2">
          Partner onboarding · {step + 1} of {SLIDES.length}
        </p>
        <h3 className="font-display text-xl text-foreground mb-3 leading-snug">{slide.title}</h3>
        <p className="text-sm text-muted-foreground leading-relaxed">{slide.body}</p>
      </div>

      {isLast && (
        <div className="rounded-lg border border-primary/20 bg-primary/5 px-4 py-3 mb-6 flex gap-3">
          <Sparkles className="w-4 h-4 text-primary flex-shrink-0 mt-0.5" />
          <p className="text-xs text-muted-foreground leading-relaxed">
            Next: a short application so we can match you to the right couples. Every category
            welcome — restaurants, bars, experiences, retail, events, and more.
          </p>
        </div>
      )}

      <button
        type="button"
        onClick={() => (isLast ? onComplete() : setStep((s) => s + 1))}
        className="flex items-center justify-center gap-2 rounded-lg bg-primary px-6 py-3.5 font-semibold text-primary-foreground w-full hover:opacity-90 transition-opacity"
      >
        {isLast ? 'Start application' : 'Next'}
        <ChevronRight className="w-4 h-4" />
      </button>

      {!isLast && (
        <button
          type="button"
          onClick={onComplete}
          className="mt-3 text-xs text-muted-foreground hover:text-foreground transition-colors"
        >
          Skip intro → apply now
        </button>
      )}
    </div>
  )
}
