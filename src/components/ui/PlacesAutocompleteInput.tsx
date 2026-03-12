import { useRef, useEffect } from "react";
import { Input } from "@/components/ui/input";
import { cn } from "@/lib/utils";

const GOOGLE_MAPS_API_KEY = import.meta.env.VITE_GOOGLE_MAPS_API_KEY;

declare global {
  interface Window {
    google?: typeof google;
  }
}

type AutocompleteMode = "city" | "address";

interface PlacesAutocompleteInputProps {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  mode?: AutocompleteMode;
  /** When true (e.g. for starting-address field), use strict address type only for clearer suggestions */
  addressOnly?: boolean;
  className?: string;
  id?: string;
}

export function PlacesAutocompleteInput({
  value,
  onChange,
  placeholder = "Start typing...",
  mode = "city",
  addressOnly = false,
  className,
  id,
}: PlacesAutocompleteInputProps) {
  const inputRef = useRef<HTMLInputElement>(null);
  const autocompleteRef = useRef<google.maps.places.Autocomplete | null>(null);
  const onChangeRef = useRef(onChange);
  onChangeRef.current = onChange;

  useEffect(() => {
    if (!GOOGLE_MAPS_API_KEY) return;

    const initAutocomplete = () => {
      if (!inputRef.current || !window.google?.maps?.places) return;

      if (autocompleteRef.current) {
        google.maps.event.clearInstanceListeners(autocompleteRef.current);
      }

      const types = mode === "city" ? ["(regions)"] : addressOnly ? ["address"] : ["address", "establishment"];
      autocompleteRef.current = new window.google.maps.places.Autocomplete(
        inputRef.current,
        { types }
      );

      autocompleteRef.current.addListener("place_changed", () => {
        const place = autocompleteRef.current?.getPlace();
        const address = place?.formatted_address || place?.name;
        if (address) {
          onChangeRef.current(address);
        }
      });
    };

    if (window.google?.maps?.places) {
      initAutocomplete();
      return;
    }

    if (document.querySelector('script[src*="maps.googleapis.com"]')) {
      const checkReady = () => {
        if (window.google?.maps?.places) {
          initAutocomplete();
        } else {
          setTimeout(checkReady, 100);
        }
      };
      checkReady();
      return;
    }

    const script = document.createElement("script");
    script.src = `https://maps.googleapis.com/maps/api/js?key=${GOOGLE_MAPS_API_KEY}&libraries=places`;
    script.async = true;
    script.defer = true;
    script.onload = () => {
      if (window.google?.maps?.places) {
        initAutocomplete();
      }
    };
    document.head.appendChild(script);

    return () => {
      if (autocompleteRef.current) {
        google.maps.event.clearInstanceListeners(autocompleteRef.current);
        autocompleteRef.current = null;
      }
    };
  }, [mode, addressOnly]);

  return (
    <Input
      ref={inputRef}
      id={id}
      type="text"
      value={value}
      onChange={(e) => onChange(e.target.value)}
      placeholder={placeholder}
      className={cn("bg-card border-border", className)}
      autoComplete="off"
    />
  );
}
