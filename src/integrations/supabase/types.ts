export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.1"
  }
  public: {
    Tables: {
      date_history: {
        Row: {
          created_at: string
          date_plan_id: string | null
          id: string
          notes: string | null
          rating: number | null
          user_id: string
          venue_id: string | null
          visited_at: string
        }
        Insert: {
          created_at?: string
          date_plan_id?: string | null
          id?: string
          notes?: string | null
          rating?: number | null
          user_id: string
          venue_id?: string | null
          visited_at?: string
        }
        Update: {
          created_at?: string
          date_plan_id?: string | null
          id?: string
          notes?: string | null
          rating?: number | null
          user_id?: string
          venue_id?: string | null
          visited_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "date_history_date_plan_id_fkey"
            columns: ["date_plan_id"]
            isOneToOne: false
            referencedRelation: "date_plans"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "date_history_venue_id_fkey"
            columns: ["venue_id"]
            isOneToOne: false
            referencedRelation: "venues"
            referencedColumns: ["id"]
          },
        ]
      }
      date_memories: {
        Row: {
          caption: string | null
          created_at: string
          date_plan_id: string | null
          id: string
          image_url: string
          is_public: boolean
          taken_at: string
          user_id: string
          venue_id: string | null
        }
        Insert: {
          caption?: string | null
          created_at?: string
          date_plan_id?: string | null
          id?: string
          image_url: string
          is_public?: boolean
          taken_at?: string
          user_id: string
          venue_id?: string | null
        }
        Update: {
          caption?: string | null
          created_at?: string
          date_plan_id?: string | null
          id?: string
          image_url?: string
          is_public?: boolean
          taken_at?: string
          user_id?: string
          venue_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "date_memories_date_plan_id_fkey"
            columns: ["date_plan_id"]
            isOneToOne: false
            referencedRelation: "date_plans"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "date_memories_venue_id_fkey"
            columns: ["venue_id"]
            isOneToOne: false
            referencedRelation: "venues"
            referencedColumns: ["id"]
          },
        ]
      }
      date_plans: {
        Row: {
          conversation_starters: Json | null
          couple_id: string | null
          created_at: string
          date_scheduled: string | null
          estimated_cost: string | null
          genie_secret_touch: Json | null
          gift_suggestions: Json | null
          id: string
          packing_list: string[] | null
          plan_options: Json | null
          rating: number | null
          rating_notes: string | null
          selected_option: string | null
          status: string
          stops: Json
          tagline: string | null
          title: string
          total_duration: string | null
          updated_at: string
          user_id: string
          weather_note: string | null
        }
        Insert: {
          conversation_starters?: Json | null
          couple_id?: string | null
          created_at?: string
          date_scheduled?: string | null
          estimated_cost?: string | null
          genie_secret_touch?: Json | null
          gift_suggestions?: Json | null
          id?: string
          packing_list?: string[] | null
          plan_options?: Json | null
          rating?: number | null
          rating_notes?: string | null
          selected_option?: string | null
          status?: string
          stops?: Json
          tagline?: string | null
          title: string
          total_duration?: string | null
          updated_at?: string
          user_id: string
          weather_note?: string | null
        }
        Update: {
          conversation_starters?: Json | null
          couple_id?: string | null
          created_at?: string
          date_scheduled?: string | null
          estimated_cost?: string | null
          genie_secret_touch?: Json | null
          gift_suggestions?: Json | null
          id?: string
          packing_list?: string[] | null
          plan_options?: Json | null
          rating?: number | null
          rating_notes?: string | null
          selected_option?: string | null
          status?: string
          stops?: Json
          tagline?: string | null
          title?: string
          total_duration?: string | null
          updated_at?: string
          user_id?: string
          weather_note?: string | null
        }
        Relationships: []
      }
      profiles: {
        Row: {
          avatar_url: string | null
          created_at: string
          display_name: string | null
          id: string
          updated_at: string
          user_id: string
        }
        Insert: {
          avatar_url?: string | null
          created_at?: string
          display_name?: string | null
          id?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          avatar_url?: string | null
          created_at?: string
          display_name?: string | null
          id?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      user_preferences: {
        Row: {
          accessibility_needs: string[] | null
          activity_preferences: string[] | null
          allergies: string[] | null
          budget_range: string | null
          created_at: string
          deal_breakers: string[] | null
          default_city: string | null
          default_neighborhood: string | null
          dietary_restrictions: string[] | null
          drink_preferences: string[] | null
          energy_level: string | null
          food_preferences: string[] | null
          gift_budget: string | null
          gift_interests: string[] | null
          gift_notes: string | null
          gift_occasion: string | null
          gift_recipient: string | null
          id: string
          preferred_location: string | null
          smoking_activities: string[] | null
          smoking_preference: string | null
          transportation_mode: string | null
          travel_radius: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          accessibility_needs?: string[] | null
          activity_preferences?: string[] | null
          allergies?: string[] | null
          budget_range?: string | null
          created_at?: string
          deal_breakers?: string[] | null
          default_city?: string | null
          default_neighborhood?: string | null
          dietary_restrictions?: string[] | null
          drink_preferences?: string[] | null
          energy_level?: string | null
          food_preferences?: string[] | null
          gift_budget?: string | null
          gift_interests?: string[] | null
          gift_notes?: string | null
          gift_occasion?: string | null
          gift_recipient?: string | null
          id?: string
          preferred_location?: string | null
          smoking_activities?: string[] | null
          smoking_preference?: string | null
          transportation_mode?: string | null
          travel_radius?: string | null
          updated_at?: string
          user_id: string
        }
        Update: {
          accessibility_needs?: string[] | null
          activity_preferences?: string[] | null
          allergies?: string[] | null
          budget_range?: string | null
          created_at?: string
          deal_breakers?: string[] | null
          default_city?: string | null
          default_neighborhood?: string | null
          dietary_restrictions?: string[] | null
          drink_preferences?: string[] | null
          energy_level?: string | null
          food_preferences?: string[] | null
          gift_budget?: string | null
          gift_interests?: string[] | null
          gift_notes?: string | null
          gift_occasion?: string | null
          gift_recipient?: string | null
          id?: string
          preferred_location?: string | null
          smoking_activities?: string[] | null
          smoking_preference?: string | null
          transportation_mode?: string | null
          travel_radius?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      user_roles: {
        Row: {
          created_at: string
          id: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          role?: Database["public"]["Enums"]["app_role"]
          user_id?: string
        }
        Relationships: []
      }
      venues: {
        Row: {
          address: string | null
          created_at: string
          google_place_id: string | null
          id: string
          latitude: number | null
          longitude: number | null
          name: string
          opentable_id: string | null
          resy_id: string | null
          venue_type: string | null
        }
        Insert: {
          address?: string | null
          created_at?: string
          google_place_id?: string | null
          id?: string
          latitude?: number | null
          longitude?: number | null
          name: string
          opentable_id?: string | null
          resy_id?: string | null
          venue_type?: string | null
        }
        Update: {
          address?: string | null
          created_at?: string
          google_place_id?: string | null
          id?: string
          latitude?: number | null
          longitude?: number | null
          name?: string
          opentable_id?: string | null
          resy_id?: string | null
          venue_type?: string | null
        }
        Relationships: []
      }
    }
    Views: {
      user_stats: {
        Row: {
          avatar_url: string | null
          display_name: string | null
          email: string | null
          last_plan_date: string | null
          last_updated: string | null
          role: Database["public"]["Enums"]["app_role"] | null
          signup_date: string | null
          total_date_plans: number | null
          user_id: string | null
        }
        Relationships: []
      }
    }
    Functions: {
      get_user_email: { Args: { _user_id: string }; Returns: string }
      has_role: {
        Args: {
          _role: Database["public"]["Enums"]["app_role"]
          _user_id: string
        }
        Returns: boolean
      }
      is_current_user_admin: { Args: never; Returns: boolean }
    }
    Enums: {
      app_role: "admin" | "moderator" | "user"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      app_role: ["admin", "moderator", "user"],
    },
  },
} as const
