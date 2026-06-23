import { useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { ArrowLeft, Sparkles } from 'lucide-react'
import { BusinessOnboarding } from '@/components/business/BusinessOnboarding'
import { BusinessListingForm } from '@/components/business/BusinessListingForm'

type PortalStep = 'onboarding' | 'apply' | 'done'

const BusinessPartnerPortal = () => {
  const [searchParams] = useSearchParams()
  const navigate = useNavigate()
  const source = searchParams.get('src') ?? 'portal'
  const email = searchParams.get('email') ?? ''
  const skipIntro = searchParams.get('skip') === '1'
  const [step, setStep] = useState<PortalStep>(skipIntro ? 'apply' : 'onboarding')

  return (
    <div className="min-h-screen bg-background flex flex-col">
      <header className="border-b border-border/60">
        <div className="container px-4 sm:px-6 lg:px-8 py-4 flex items-center justify-between gap-4 max-w-3xl mx-auto">
          <Link
            to="/for-business"
            className="inline-flex items-center gap-2 text-sm text-muted-foreground hover:text-foreground transition-colors"
          >
            <ArrowLeft className="w-4 h-4" />
            For Business
          </Link>
          <div className="flex items-center gap-2">
            <Sparkles className="w-4 h-4 text-primary" />
            <span className="font-display text-lg text-foreground">Partner portal</span>
          </div>
        </div>
      </header>

      <main className="flex-1 container px-4 sm:px-6 lg:px-8 py-10 max-w-xl mx-auto w-full">
        {step === 'onboarding' && (
          <BusinessOnboarding onComplete={() => setStep('apply')} />
        )}

        {step === 'apply' && (
          <>
            <h1 className="font-display text-2xl text-foreground mb-2">Advertising application</h1>
            <p className="text-sm text-muted-foreground mb-6 leading-relaxed">
              Tell us about your business so we can match you to couples planning date nights in your
              area. All categories welcome.
            </p>
            <BusinessListingForm
              source={source}
              defaultEmail={email}
              onSuccess={() => setStep('done')}
            />
            <p className="mt-5 text-xs text-muted-foreground text-center leading-relaxed">
              Stored securely in Firebase <code className="text-foreground/80">business_listings</code>.
              We'll email you within a few business days.
            </p>
          </>
        )}

        {step === 'done' && (
          <div className="text-center py-8">
            <h1 className="font-display text-2xl text-foreground mb-3">You're on the list</h1>
            <p className="text-sm text-muted-foreground mb-8 leading-relaxed">
              We'll review your application and send placement options. Meanwhile you can explore what
              couples see in the app.
            </p>
            <Link
              to="/for-business"
              className="inline-flex items-center justify-center rounded-lg bg-primary px-6 py-3 font-semibold text-primary-foreground hover:opacity-90"
            >
              Back to For Business
            </Link>
            <button
              type="button"
              onClick={() => navigate('/app')}
              className="block mx-auto mt-4 text-sm text-primary hover:underline"
            >
              Preview the couple app →
            </button>
          </div>
        )}
      </main>
    </div>
  )
}

export default BusinessPartnerPortal
