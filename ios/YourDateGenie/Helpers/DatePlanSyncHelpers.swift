import Foundation

// MARK: - DatePlan ↔ DBDatePlan conversion for cloud sync (Supabase `public.date_plans`)

enum DatePlanSyncHelpers {
    
    /// Convert a plan from the database into the app's DatePlan model (e.g. after fetch on login).
    static func datePlan(from db: DBDatePlan) -> DatePlan {
        DatePlan(
            id: db.id,
            optionLabel: db.selectedOption,
            title: db.title,
            tagline: db.tagline ?? "",
            totalDuration: db.totalDuration ?? "—",
            estimatedCost: db.estimatedCost ?? "—",
            stops: db.stops,
            startingPoint: db.startingPoint,
            genieSecretTouch: db.genieSecretTouch ?? GenieSecretTouch(title: "", description: "", emoji: "✨"),
            packingList: db.packingList ?? [],
            weatherNote: db.weatherNote ?? "",
            giftSuggestions: db.giftSuggestions,
            conversationStarters: db.conversationStarters,
            scheduledDate: db.dateScheduled,
            createdAt: db.createdAt ?? Date()
        )
    }

    /// Convert the app's DatePlan to a row for `public.date_plans` (same shape the web app uses).
    static func dbDatePlan(from plan: DatePlan, userId: UUID, coupleId: UUID, status: String = "planned") -> DBDatePlan {
        DBDatePlan(
            id: plan.id,
            userId: userId,
            coupleId: coupleId,
            dateScheduled: plan.scheduledDate,
            title: plan.title,
            tagline: plan.tagline.isEmpty ? nil : plan.tagline,
            totalDuration: plan.totalDuration,
            estimatedCost: plan.estimatedCost,
            stops: plan.stops,
            startingPoint: plan.startingPoint,
            genieSecretTouch: plan.genieSecretTouch,
            packingList: plan.packingList.isEmpty ? nil : plan.packingList,
            weatherNote: plan.weatherNote.isEmpty ? nil : plan.weatherNote,
            status: status,
            selectedOption: plan.optionLabel,
            planOptions: nil,
            giftSuggestions: plan.giftSuggestions,
            conversationStarters: plan.conversationStarters,
            rating: nil,
            ratingNotes: nil,
            createdAt: nil,
            updatedAt: nil
        )
    }
}
