import { useState } from "react";
import { X, MapPin, Phone } from "lucide-react";
import { Dialog, DialogContent, DialogTitle, DialogDescription } from "./ui/dialog";
import { Client } from "./MobileClients";
import { DataService } from "../services/DataService";
import visitImage from 'figma:asset/b960bb8bf047a63e4427abf8a71f0f68d9c2293d.png';

interface TouchpointModalProps {
  isOpen: boolean;
  onClose: () => void;
  touchpoint: {
    id: number;
    type: 'Visit' | 'Call';
    date: string;
    notes?: string;
  } | null;
  client: Client;
}

const REASON_TYPES = [
  'ABROAD',
  'APPLY FOR PUSU MEMBERSHIP / LIKA MEMBERSHIP',
  'BACKED OUT',
  'CI/BI',
  'DECEASED',
  'DISAPPROVED',
  'FOR ADA COMPLIANCE',
  'FOR PROCESSING / APPROVAL / REQUEST / BUY-OUT',
  'FOR UPDATE',
  'FOR VERIFICATION',
  'INACCESSIBLE / CRITICAL AREA',
  'INTERESTED',
  'LOAN INQUIRY',
  'MOVED OUT',
  'NOT AMENABLE TO OUR PRODUCT CRITERIA',
  'NOT AROUND',
  'NOT IN THE LIST',
  'NOT INTERESTED',
  'OVERAGE',
  'POOR HEALTH CONDITION',
  'RETURNED ATM / PICK-UP ATM',
  'UNDECIDED',
  'UNLOCATED',
  'WITH OTHER LENDING',
  'INTERESTED, BUT DECLINED DUE TO FAMILY\'S DECISION',
  'TELEMARKETING'
];

export function TouchpointModal({ isOpen, onClose, touchpoint, client }: TouchpointModalProps) {
  if (!touchpoint) return null;

  // Get real visit data from DataService
  const clientDetails = DataService.getClientDetails(parseInt(client.id));
  const realVisit = clientDetails?.visits.find(visit => visit.Touchpoint === touchpoint.id);
  
  const getOrdinal = (num: number) => {
    const ordinals = ['1st', '2nd', '3rd', '4th', '5th', '6th', '7th'];
    return ordinals[num - 1] || `${num}th`;
  };

  const getTouchpointIcon = (type: 'Visit' | 'Call') => {
    if (type === 'Visit') {
      return <MapPin className="w-8 h-8 text-green-600" />;
    } else {
      return <Phone className="w-8 h-8 text-green-600" />;
    }
  };

  const formatTime = (time: string) => {
    if (!time) return 'N/A';
    return time;
  };

  const formatDate = (dateStr: string) => {
    if (!dateStr) return 'N/A';
    const date = new Date(dateStr);
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return `${months[date.getMonth()]} ${date.getDate()}, ${date.getFullYear()}`;
  };

  // Use real data or fallback to touchpoint data
  const visitData = {
    date: realVisit?.DateOfVisit || touchpoint.date,
    address: realVisit?.Address || 'N/A',
    clientType: realVisit?.ClientType === 'POTENTIAL' ? 'Potential Client' : 'Existing Client',
    reason: realVisit?.Reason || 'N/A',
    timeArrival: formatTime(realVisit?.TimeArrival || ''),
    timeDeparture: formatTime(realVisit?.TimeDeparture || ''),
    odometerArrival: realVisit?.OdometerArrival || '',
    odometerDeparture: realVisit?.OdometerDeparture || '',
    nextVisitDate: formatDate(realVisit?.NextVisitDate || ''),
    remarks: realVisit?.Remarks || touchpoint.notes || 'None'
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="w-[350px] p-0 bg-white rounded-lg overflow-hidden">
        <DialogTitle className="sr-only">
          Touchpoint Details - {getOrdinal(touchpoint.id)} {touchpoint.type}
        </DialogTitle>
        <DialogDescription className="sr-only">
          Detailed information about the {touchpoint.type.toLowerCase()} touchpoint including date, time, address, client type, reason, and visit details.
        </DialogDescription>
        <div className="relative">
          {/* Header */}
          <div className="p-4 border-b border-gray-200">
            <div>
              <p className="text-sm text-gray-600">{formatDate(visitData.date)}</p>
              <p className="text-sm text-gray-500 mt-1">{visitData.address}</p>
            </div>
          </div>

          {/* Touchpoint Info */}
          <div className="p-4 border-b border-gray-200">
            <div className="flex items-center space-x-4">
              <div className="flex flex-col items-center p-3 border border-gray-200 rounded-lg">
                {getTouchpointIcon(touchpoint.type)}
                <span className="text-sm text-gray-600 mt-1">{getOrdinal(touchpoint.id)}</span>
              </div>
              <div className="flex-1">
                <h3 className="text-base text-black">{visitData.clientType}</h3>
                <p className="text-sm text-gray-600">{visitData.reason}</p>
              </div>
            </div>
          </div>

          {/* Visit Image - Only for Visit touchpoints */}
          {touchpoint.type === 'Visit' && (
            <div className="p-4 border-b border-gray-200">
              <img 
                src={visitImage} 
                alt="Field agent meeting with client"
                className="w-full h-auto rounded-lg"
              />
            </div>
          )}

          {/* Visit Details */}
          <div className="p-4 space-y-3 text-sm">
            <div className="flex justify-between">
              <span className="text-gray-600">Time of Arrival:</span>
              <span className="text-black">{visitData.timeArrival}</span>
            </div>
            {visitData.odometerArrival && (
              <div className="flex justify-between">
                <span className="text-gray-600">Odometer Arrival:</span>
                <span className="text-black">{visitData.odometerArrival}</span>
              </div>
            )}
            <div className="flex justify-between">
              <span className="text-gray-600">Time of Departure:</span>
              <span className="text-black">{visitData.timeDeparture}</span>
            </div>
            {visitData.odometerDeparture && (
              <div className="flex justify-between">
                <span className="text-gray-600">Odometer Departure:</span>
                <span className="text-black">{visitData.odometerDeparture}</span>
              </div>
            )}
            <div className="flex justify-between">
              <span className="text-gray-600">Next Visit Date:</span>
              <span className="text-black">{visitData.nextVisitDate}</span>
            </div>
          </div>

          {/* Other Remarks */}
          <div className="p-4">
            <h4 className="text-sm text-gray-900 mb-2">Other Remarks:</h4>
            <p className="text-sm text-gray-600">{visitData.remarks}</p>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}