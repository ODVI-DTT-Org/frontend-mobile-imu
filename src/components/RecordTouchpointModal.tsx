import { useState } from "react";
import { MapPin, Phone } from "lucide-react";
import { Sheet, SheetContent, SheetHeader, SheetTitle } from "./ui/sheet";

const REASONS = [
  'INTERESTED',
  'NOT INTERESTED',
  'UNDECIDED',
  'LOAN INQUIRY',
  'FOR UPDATE',
  'FOR VERIFICATION',
  'NOT AROUND',
  'FOR ADA COMPLIANCE',
  'FOR PROCESSING / APPROVAL / REQUEST / BUY-OUT',
  'ABROAD',
  'BACKED OUT',
  'DECEASED',
  'MOVED OUT',
  'UNLOCATED',
  'WITH OTHER LENDING',
  'POOR HEALTH CONDITION',
  'TELEMARKETING',
];

interface RecordTouchpointModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (visitId: number) => void;
  visit: {
    VisitID: number;
    clientName: string;
    TouchpointType: string;
    Touchpoint: number;
  } | null;
}

export function RecordTouchpointModal({ isOpen, onClose, onSubmit, visit }: RecordTouchpointModalProps) {
  const [reason, setReason] = useState('INTERESTED');
  const [remarks, setRemarks] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  if (!visit) return null;

  // Bug 6 fix: read TouchpointType directly from visit, no pattern inference
  const touchpointType = visit.TouchpointType;
  const ordinals = ['', '1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th', '10th'];
  const ordinal = ordinals[visit.Touchpoint] || `${visit.Touchpoint}th`;

  const handleSubmit = () => {
    setIsSubmitting(true);
    // Simulate network delay
    setTimeout(() => {
      onSubmit(visit.VisitID);
      setReason('INTERESTED');
      setRemarks('');
      setIsSubmitting(false);
    }, 500);
  };

  return (
    <Sheet open={isOpen} onOpenChange={(open) => { if (!open) onClose(); }}>
      <SheetContent side="bottom" className="rounded-t-2xl pb-8 max-h-[85vh] overflow-y-auto">
        <SheetHeader className="mb-4">
          <SheetTitle className="text-left">Record Touchpoint</SheetTitle>
          <div className="flex items-center space-x-2 text-sm text-gray-500">
            {touchpointType === 'Visit'
              ? <MapPin className="w-4 h-4" />
              : <Phone className="w-4 h-4" />
            }
            <span>{ordinal} {touchpointType} — {visit.clientName}</span>
          </div>
        </SheetHeader>

        <div className="space-y-4">
          {/* Reason */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Reason *</label>
            <select
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              className="w-full border border-gray-300 rounded-lg px-3 py-2.5 text-sm text-black bg-white focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              {REASONS.map((r) => (
                <option key={r} value={r}>{r}</option>
              ))}
            </select>
          </div>

          {/* Remarks */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Remarks</label>
            <textarea
              value={remarks}
              onChange={(e) => setRemarks(e.target.value)}
              placeholder="Optional notes..."
              rows={3}
              className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm text-black resize-none focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          {/* Submit */}
          <button
            onClick={handleSubmit}
            disabled={isSubmitting}
            className="w-full bg-blue-600 text-white py-3 rounded-lg text-sm font-medium hover:bg-blue-700 active:bg-blue-800 disabled:opacity-60 transition-colors"
          >
            {isSubmitting ? 'Saving...' : 'Submit Touchpoint'}
          </button>
        </div>
      </SheetContent>
    </Sheet>
  );
}
