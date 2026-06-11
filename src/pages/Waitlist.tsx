import { useSearchParams } from 'react-router-dom'
import { Sparkles, Heart, Calendar, Zap } from 'lucide-react'
import { WaitlistForm } from '@/components/waitlist/WaitlistForm'

const PERKS = [
  { icon: Zap, text: 'First TestFlight access — day we go live' },
  { icon: Calendar, text: 'AI-generated date itineraries in 60 seconds' },
  { icon: Heart, text: 'Gift ideas, love notes & playlist — all personalized' },
]

const Waitlist = () => {
  const [searchParams] = useSearchParams()
  const source = searchParams.get('src') ?? 'direct'

  return (
    <div className="min-h-screen bg-background flex flex-col">
      {/* Background decorations */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-1/4 left-1/4 w-[300px] h-[300px] bg-primary/8 rounded-full blur-3xl animate-pulse" />
        <div
          className="absolute bottom-1/3 right-1/4 w-[250px] h-[250px] bg-primary/5 rounded-full blur-3xl animate-pulse"
          style={{ animationDelay: '1.2s' }}
        />
      </div>

      <main className="flex-1 flex items-center justify-center px-4 py-16 relative z-10">
        <div className="w-full max-w-md">
          {/* Logo mark */}
          <div className="flex justify-center mb-8">
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 rounded-full border-2 border-primary/40 flex items-center justify-center bg-primary/10">
                <Sparkles className="w-6 h-6 text-primary" />
              </div>
              <div className="flex flex-col leading-tight">
                <span className="text-xs text-muted-foreground tracking-widest uppercase">Your Date</span>
                <span className="font-display text-2xl text-foreground tracking-wide">GENIE</span>
              </div>
            </div>
          </div>

          {/* Card */}
          <div className="rounded-2xl border border-border bg-card/60 backdrop-blur-sm p-8 shadow-xl">
            {/* Badge */}
            <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-primary/10 border border-primary/20 mb-5">
              <span className="w-2 h-2 rounded-full bg-primary animate-pulse" />
              <span className="text-primary text-xs font-semibold uppercase tracking-wider">Launching soon</span>
            </div>

            <h1 className="font-display text-3xl sm:text-4xl text-foreground mb-3 leading-tight">
              Get early access to<br />
              <span className="text-gradient-gold">Date Genie</span>
            </h1>

            <p className="text-muted-foreground text-base mb-8 leading-relaxed">
              We're launching soon. Drop your email and we'll send you a TestFlight
              invite the day we go live.
            </p>

            {/* Perks */}
            <ul className="space-y-3 mb-8">
              {PERKS.map(({ icon: Icon, text }) => (
                <li key={text} className="flex items-start gap-3 text-sm text-foreground">
                  <span className="mt-0.5 flex-shrink-0 w-6 h-6 rounded-full bg-primary/10 flex items-center justify-center">
                    <Icon className="w-3.5 h-3.5 text-primary" />
                  </span>
                  {text}
                </li>
              ))}
            </ul>

            {/* Form */}
            <WaitlistForm
              source={source}
              layout="stacked"
              showPartnerField
            />

            <p className="mt-5 text-xs text-muted-foreground text-center leading-relaxed">
              By joining, you agree to receive launch updates from Your Date Genie.
              We will never share your email with anyone.
            </p>
          </div>

          {/* Social proof */}
          <p className="mt-6 text-center text-sm text-muted-foreground">
            Join{' '}
            <span className="text-primary font-semibold">500+ couples</span>{' '}
            already on the waitlist
          </p>
        </div>
      </main>
    </div>
  )
}

export default Waitlist
