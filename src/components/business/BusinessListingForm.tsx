import { useState, useEffect } from 'react'
import { CheckCircle, Loader2, ArrowRight, Store } from 'lucide-react'
import { useBusinessListing } from '@/hooks/useBusinessListing'
import {
  BUSINESS_VENUE_CATEGORIES,
  PROMOTION_INTERESTS,
  BUDGET_RANGES,
  type BusinessVenueCategory,
  type PromotionInterest,
  type BudgetRange,
} from '@/lib/businessCategories'
import { Label } from '@/components/ui/label'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { cn } from '@/lib/utils'

interface BusinessListingFormProps {
  source: string
  className?: string
  defaultEmail?: string
  onSuccess?: () => void
}

export function BusinessListingForm({
  source,
  className,
  defaultEmail = '',
  onSuccess,
}: BusinessListingFormProps) {
  const [businessName, setBusinessName] = useState('')
  const [contactName, setContactName] = useState('')
  const [contactRole, setContactRole] = useState('')
  const [email, setEmail] = useState(defaultEmail)
  const [phone, setPhone] = useState('')
  const [website, setWebsite] = useState('')
  const [streetAddress, setStreetAddress] = useState('')
  const [city, setCity] = useState('')
  const [state, setState] = useState('')
  const [zip, setZip] = useState('')
  const [venueCategory, setVenueCategory] = useState<BusinessVenueCategory>('restaurant')
  const [venueCategoryOther, setVenueCategoryOther] = useState('')
  const [aboutVenue, setAboutVenue] = useState('')
  const [coupleExperience, setCoupleExperience] = useState('')
  const [promotionInterest, setPromotionInterest] =
    useState<PromotionInterest>('featured_itinerary')
  const [promotionOther, setPromotionOther] = useState('')
  const [budgetRange, setBudgetRange] = useState<BudgetRange>('unsure')
  const [additionalNotes, setAdditionalNotes] = useState('')
  const { status, errorMessage, submit } = useBusinessListing()

  useEffect(() => {
    if (status === 'success') onSuccess?.()
  }, [status, onSuccess])

  const inputClass = cn(
    'w-full rounded-lg border border-border bg-background/60 px-4 py-3 text-foreground placeholder:text-muted-foreground',
    'focus:outline-none focus:ring-2 focus:ring-primary/50 disabled:opacity-50'
  )

  if (status === 'success') {
    return (
      <div className={cn('rounded-xl bg-green-950/30 border border-green-500/30 p-6 text-center', className)}>
        <CheckCircle className="w-8 h-8 text-green-400 mx-auto mb-2" />
        <p className="font-semibold text-green-300 text-lg">Application received</p>
        <p className="text-green-400/80 text-sm mt-2 leading-relaxed">
          Thanks, {contactName.split(' ')[0] || 'there'}! We'll review {businessName} and email you
          within a few business days with placement options.
        </p>
      </div>
    )
  }

  if (status === 'duplicate') {
    return (
      <div className={cn('rounded-xl bg-blue-950/30 border border-blue-500/30 p-6 text-center', className)}>
        <Store className="w-8 h-8 text-blue-400 mx-auto mb-2" />
        <p className="font-semibold text-blue-300 text-lg">We already have your application</p>
        <p className="text-blue-400/80 text-sm mt-2">
          {businessName || 'Your business'} already applied with this email. We'll be in touch soon.
        </p>
      </div>
    )
  }

  const isSubmitting = status === 'submitting'

  return (
    <div className={cn('w-full', className)}>
      <form
        onSubmit={(e) => {
          e.preventDefault()
          submit({
            businessName,
            contactName,
            contactRole: contactRole || undefined,
            email,
            phone,
            website: website || undefined,
            streetAddress,
            city,
            state,
            zip: zip || undefined,
            venueCategory,
            venueCategoryOther:
              venueCategory === 'other' ? venueCategoryOther : undefined,
            aboutVenue,
            coupleExperience,
            promotionInterest,
            promotionOther: promotionInterest === 'other' ? promotionOther : undefined,
            budgetRange,
            additionalNotes: additionalNotes || undefined,
            source,
          })
        }}
        className="flex flex-col gap-4"
      >
        <div>
          <p className="text-xs font-semibold uppercase tracking-wider text-primary mb-3">
            Business details
          </p>
          <div className="flex flex-col gap-3">
            <input
              type="text"
              required
              value={businessName}
              onChange={(e) => setBusinessName(e.target.value)}
              placeholder="Business name *"
              disabled={isSubmitting}
              className={inputClass}
            />
            <div className="grid sm:grid-cols-2 gap-3">
              <input
                type="text"
                required
                value={contactName}
                onChange={(e) => setContactName(e.target.value)}
                placeholder="Your name *"
                disabled={isSubmitting}
                className={inputClass}
              />
              <input
                type="text"
                value={contactRole}
                onChange={(e) => setContactRole(e.target.value)}
                placeholder="Your role (optional)"
                disabled={isSubmitting}
                className={inputClass}
              />
            </div>
          </div>
        </div>

        <div>
          <p className="text-xs font-semibold uppercase tracking-wider text-primary mb-3">
            Category
          </p>
          <Label className="text-xs text-muted-foreground mb-1.5 block">
            What kind of date spot is it? *
          </Label>
          <Select
            value={venueCategory}
            onValueChange={(v) => setVenueCategory(v as BusinessVenueCategory)}
            disabled={isSubmitting}
          >
            <SelectTrigger className={inputClass}>
              <SelectValue placeholder="Select a category" />
            </SelectTrigger>
            <SelectContent>
              {BUSINESS_VENUE_CATEGORIES.map(({ value, label }) => (
                <SelectItem key={value} value={value}>
                  {label}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          {venueCategory === 'other' && (
            <input
              type="text"
              required
              value={venueCategoryOther}
              onChange={(e) => setVenueCategoryOther(e.target.value)}
              placeholder="Describe your category *"
              disabled={isSubmitting}
              className={cn(inputClass, 'mt-3')}
            />
          )}
        </div>

        <div>
          <p className="text-xs font-semibold uppercase tracking-wider text-primary mb-3">
            Location
          </p>
          <div className="flex flex-col gap-3">
            <input
              type="text"
              required
              value={streetAddress}
              onChange={(e) => setStreetAddress(e.target.value)}
              placeholder="Street address *"
              disabled={isSubmitting}
              className={inputClass}
            />
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
              <input
                type="text"
                required
                value={city}
                onChange={(e) => setCity(e.target.value)}
                placeholder="City *"
                disabled={isSubmitting}
                className={inputClass}
              />
              <input
                type="text"
                required
                value={state}
                onChange={(e) => setState(e.target.value)}
                placeholder="State *"
                disabled={isSubmitting}
                className={inputClass}
              />
              <input
                type="text"
                value={zip}
                onChange={(e) => setZip(e.target.value)}
                placeholder="ZIP"
                disabled={isSubmitting}
                className={inputClass}
              />
            </div>
          </div>
        </div>

        <div>
          <p className="text-xs font-semibold uppercase tracking-wider text-primary mb-3">
            Contact
          </p>
          <div className="flex flex-col gap-3">
            <input
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="Work email *"
              disabled={isSubmitting}
              className={inputClass}
            />
            <input
              type="tel"
              required
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              placeholder="Phone *"
              disabled={isSubmitting}
              className={inputClass}
            />
            <input
              type="url"
              value={website}
              onChange={(e) => setWebsite(e.target.value)}
              placeholder="Website or Instagram (optional)"
              disabled={isSubmitting}
              className={inputClass}
            />
          </div>
        </div>

        <div>
          <p className="text-xs font-semibold uppercase tracking-wider text-primary mb-3">
            Tell us about your spot
          </p>
          <div className="flex flex-col gap-3">
            <textarea
              required
              value={aboutVenue}
              onChange={(e) => setAboutVenue(e.target.value)}
              placeholder="What do you offer? Hours, vibe, price range… *"
              disabled={isSubmitting}
              rows={3}
              className={cn(inputClass, 'resize-none')}
            />
            <textarea
              required
              value={coupleExperience}
              onChange={(e) => setCoupleExperience(e.target.value)}
              placeholder="Why is it great for couples on a date? *"
              disabled={isSubmitting}
              rows={3}
              className={cn(inputClass, 'resize-none')}
            />
          </div>
        </div>

        <div>
          <p className="text-xs font-semibold uppercase tracking-wider text-primary mb-3">
            Advertising interest
          </p>
          <Label className="text-xs text-muted-foreground mb-1.5 block">
            What are you looking for? *
          </Label>
          <Select
            value={promotionInterest}
            onValueChange={(v) => setPromotionInterest(v as PromotionInterest)}
            disabled={isSubmitting}
          >
            <SelectTrigger className={inputClass}>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {PROMOTION_INTERESTS.map(({ value, label }) => (
                <SelectItem key={value} value={value}>
                  {label}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          {promotionInterest === 'other' && (
            <input
              type="text"
              required
              value={promotionOther}
              onChange={(e) => setPromotionOther(e.target.value)}
              placeholder="Describe what you're looking for *"
              disabled={isSubmitting}
              className={cn(inputClass, 'mt-3')}
            />
          )}
          <Label className="text-xs text-muted-foreground mb-1.5 block mt-3">
            Monthly budget interest
          </Label>
          <Select
            value={budgetRange}
            onValueChange={(v) => setBudgetRange(v as BudgetRange)}
            disabled={isSubmitting}
          >
            <SelectTrigger className={inputClass}>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {BUDGET_RANGES.map(({ value, label }) => (
                <SelectItem key={value} value={value}>
                  {label}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

        <textarea
          value={additionalNotes}
          onChange={(e) => setAdditionalNotes(e.target.value)}
          placeholder="Anything else we should know? (optional)"
          disabled={isSubmitting}
          rows={2}
          className={cn(inputClass, 'resize-none')}
        />

        <button
          type="submit"
          disabled={isSubmitting}
          className={cn(
            'flex items-center justify-center gap-2 rounded-lg bg-primary px-6 py-4 font-semibold text-primary-foreground',
            'hover:opacity-90 transition-all disabled:opacity-50 w-full mt-2'
          )}
        >
          {isSubmitting ? (
            <>
              <Loader2 className="w-4 h-4 animate-spin" />
              Submitting application…
            </>
          ) : (
            <>
              Submit application
              <ArrowRight className="w-4 h-4" />
            </>
          )}
        </button>
      </form>

      {status === 'error' && (
        <p className="mt-2 text-sm text-red-400">{errorMessage ?? 'Something went wrong. Please try again.'}</p>
      )}
    </div>
  )
}
