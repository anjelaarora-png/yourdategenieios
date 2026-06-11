import { useState } from 'react'
import { CheckCircle, Loader2, ArrowRight, Heart } from 'lucide-react'
import { useWaitlist } from '@/hooks/useWaitlist'
import { cn } from '@/lib/utils'

interface WaitlistFormProps {
  source: string
  className?: string
  /** "inline" = compact (hero/landing); "stacked" = full-page (Waitlist.tsx) */
  layout?: 'inline' | 'stacked'
  showPartnerField?: boolean
}

export function WaitlistForm({
  source,
  className,
  layout = 'inline',
  showPartnerField = false,
}: WaitlistFormProps) {
  const [email, setEmail] = useState('')
  const [fullName, setFullName] = useState('')
  const [city, setCity] = useState('')
  const [phone, setPhone] = useState('')
  const [partnerEmail, setPartnerEmail] = useState('')
  const [showPartner, setShowPartner] = useState(false)
  const { status, errorMessage, submit } = useWaitlist()

  if (status === 'success') {
    return (
      <div className={cn('rounded-xl bg-green-950/30 border border-green-500/30 p-5 text-center', className)}>
        <CheckCircle className="w-8 h-8 text-green-400 mx-auto mb-2" />
        <p className="font-semibold text-green-300 text-lg">You're on the list!</p>
        <p className="text-green-400/80 text-sm mt-1">
          We'll email you a TestFlight invite the day we go live.
        </p>
      </div>
    )
  }

  if (status === 'duplicate') {
    return (
      <div className={cn('rounded-xl bg-blue-950/30 border border-blue-500/30 p-5 text-center', className)}>
        <Heart className="w-8 h-8 text-blue-400 mx-auto mb-2 fill-blue-400" />
        <p className="font-semibold text-blue-300 text-lg">Already on the list!</p>
        <p className="text-blue-400/80 text-sm mt-1">
          See you at launch. We'll be in touch soon.
        </p>
      </div>
    )
  }

  const isSubmitting = status === 'submitting'

  const inputClass = cn(
    'w-full rounded-lg border border-border bg-background/60 px-4 py-3 text-foreground placeholder:text-muted-foreground',
    'focus:outline-none focus:ring-2 focus:ring-primary/50 disabled:opacity-50'
  )

  return (
    <div className={cn('w-full', className)}>
      <form
        onSubmit={(e) => {
          e.preventDefault()
          submit({
            email,
            fullName,
            city,
            phone: phone || undefined,
            source,
            partnerEmail: showPartner ? partnerEmail : undefined,
          })
        }}
        className="flex flex-col gap-3"
      >
        <input
          type="text"
          required
          value={fullName}
          onChange={(e) => setFullName(e.target.value)}
          placeholder="Your full name"
          disabled={isSubmitting}
          className={inputClass}
        />

        <input
          type="email"
          required
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          placeholder="you@example.com"
          disabled={isSubmitting}
          className={inputClass}
        />

        <input
          type="text"
          required
          value={city}
          onChange={(e) => setCity(e.target.value)}
          placeholder="City (e.g. New York, Mumbai)"
          disabled={isSubmitting}
          className={inputClass}
        />

        <input
          type="tel"
          value={phone}
          onChange={(e) => setPhone(e.target.value)}
          placeholder="Phone number (optional)"
          disabled={isSubmitting}
          className={inputClass}
        />

        {showPartnerField && showPartner && (
          <input
            type="email"
            value={partnerEmail}
            onChange={(e) => setPartnerEmail(e.target.value)}
            placeholder="partner@example.com"
            disabled={isSubmitting}
            className={inputClass}
          />
        )}

        <button
          type="submit"
          disabled={isSubmitting}
          className={cn(
            'flex items-center justify-center gap-2 rounded-lg bg-primary px-6 py-3 font-semibold text-primary-foreground',
            'hover:opacity-90 hover:scale-[1.02] transition-all disabled:opacity-50 disabled:scale-100',
            layout === 'stacked' ? 'w-full py-4 text-base' : 'w-full'
          )}
        >
          {isSubmitting ? (
            <>
              <Loader2 className="w-4 h-4 animate-spin" />
              Adding…
            </>
          ) : (
            <>
              Join Waitlist
              <ArrowRight className="w-4 h-4" />
            </>
          )}
        </button>
      </form>

      {showPartnerField && !showPartner && (
        <button
          type="button"
          onClick={() => setShowPartner(true)}
          className="mt-3 text-sm text-muted-foreground hover:text-foreground transition-colors underline-offset-2 hover:underline"
        >
          + Bringing your partner? Add their email too
        </button>
      )}

      {status === 'error' && (
        <p className="mt-2 text-sm text-red-400">{errorMessage ?? 'Something went wrong. Please try again.'}</p>
      )}
    </div>
  )
}
