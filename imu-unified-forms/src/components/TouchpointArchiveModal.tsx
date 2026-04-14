import { MapPin, Phone, X } from "lucide-react";
import { Dialog, DialogContent, DialogTitle, DialogDescription } from "./ui/dialog";
import { Client } from "./MobileClients";

interface TouchpointArchiveModalProps {
  isOpen: boolean;
  onClose: () => void;
  client: Client;
  onTouchpointSelect: (touchpoint: any) => void;
}

interface Touchpoint {
  id: number;
  type: 'Visit' | 'Call';
  date: string;
  notes?: string;
}

export function TouchpointArchiveModal({ isOpen, onClose, client, onTouchpointSelect }: TouchpointArchiveModalProps) {
  // Generate all touchpoints for this client based on their progress
  const generateAllTouchpoints = (): Touchpoint[] => {
    const touchpoints: Touchpoint[] = [];
    const touchpointTypes: ('Visit' | 'Call')[] = ['Visit', 'Call', 'Call', 'Visit', 'Call', 'Call', 'Visit'];
    
    for (let i = 0; i < Math.max(client.touchpointProgress, 7); i++) {
      const baseDate = new Date('2024-01-15');
      baseDate.setDate(baseDate.getDate() + (i * 3)); // 3 days apart
      
      touchpoints.push({
        id: i + 1,
        type: touchpointTypes[i % touchpointTypes.length],
        date: baseDate.toISOString().split('T')[0],
        notes: getRandomNotes(touchpointTypes[i % touchpointTypes.length])
      });
    }
    
    return touchpoints;
  };

  const getRandomNotes = (type: 'Visit' | 'Call') => {
    const visitNotes = [
      'Initial meeting completed',
      'Document review session',
      'Product demonstration',
      'Final presentation',
      'Contract signing meeting',
      'Follow-up visit',
      'Closing discussion'
    ];
    
    const callNotes = [
      'Follow up call completed',
      'Product discussion over phone',
      'Status update call',
      'Price negotiation call',
      'Clarification call',
      'Confirmation call',
      'Scheduling call'
    ];
    
    const notes = type === 'Visit' ? visitNotes : callNotes;
    return notes[Math.floor(Math.random() * notes.length)];
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return `${months[date.getMonth()]} ${date.getDate()}, ${date.getFullYear()}`;
  };

  const getOrdinal = (num: number) => {
    const ordinals = ['1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th', '10th'];
    return ordinals[num - 1] || `${num}th`;
  };

  const allTouchpoints = generateAllTouchpoints();
  const completedTouchpoints = allTouchpoints.slice(0, client.touchpointProgress);

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="w-[350px] max-h-[600px] p-0 bg-white rounded-lg overflow-hidden">
        <DialogTitle className="sr-only">
          Touchpoint Archive for {client.name}
        </DialogTitle>
        <DialogDescription className="sr-only">
          Complete history of all touchpoints for this client including visits and calls.
        </DialogDescription>
        <div className="relative">
          {/* Header */}
          <div className="p-4 border-b border-gray-200 sticky top-0 bg-white">
            <div className="flex items-center justify-between">
              <h2 className="text-lg text-black">Touchpoint Archive</h2>

            </div>
            <p className="text-sm text-gray-600 mt-1">{client.name}</p>
            <p className="text-sm text-gray-500">
              {completedTouchpoints.length} of {allTouchpoints.length} touchpoints completed
            </p>
          </div>

          {/* Touchpoints List */}
          <div className="max-h-[400px] overflow-y-auto">
            {allTouchpoints.map((touchpoint, index) => {
              const isCompleted = index <= client.touchpointProgress - 1;
              const isClickable = isCompleted;
              
              return (
                <button
                  key={touchpoint.id}
                  onClick={() => {
                    if (isClickable) {
                      onTouchpointSelect(touchpoint);
                      onClose();
                    }
                  }}
                  disabled={!isClickable}
                  className={`w-full p-4 border-b border-gray-100 text-left transition-colors ${
                    isCompleted 
                      ? 'hover:bg-gray-50 cursor-pointer' 
                      : 'cursor-not-allowed opacity-50'
                  }`}
                >
                  <div className="flex items-center space-x-4">
                    <div className="flex flex-col items-center">
                      {touchpoint.type === 'Visit' ? (
                        <MapPin className={`w-6 h-6 ${isCompleted ? 'text-green-600' : 'text-gray-400'}`} />
                      ) : (
                        <Phone className={`w-6 h-6 ${isCompleted ? 'text-green-600' : 'text-gray-400'}`} />
                      )}
                      <span className="text-xs text-gray-600 mt-1">{getOrdinal(touchpoint.id)}</span>
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center justify-between">
                        <h3 className="text-sm text-black">
                          {getOrdinal(touchpoint.id)} {touchpoint.type}
                        </h3>
                        <span className="text-xs text-gray-500">
                          {formatDate(touchpoint.date)}
                        </span>
                      </div>
                      <p className="text-sm text-gray-600 mt-1">
                        {isCompleted ? touchpoint.notes : 'Pending'}
                      </p>
                      {isCompleted && (
                        <div className="flex items-center mt-2">
                          <div className="w-2 h-2 bg-green-500 rounded-full mr-2"></div>
                          <span className="text-xs text-green-600">Completed</span>
                        </div>
                      )}
                    </div>
                  </div>
                </button>
              );
            })}
          </div>

          {/* Footer Stats */}
          <div className="p-4 border-t border-gray-200 bg-gray-50">
            <div className="flex justify-between text-sm">
              <span className="text-gray-600">Total Visits:</span>
              <span className="text-black">
                {completedTouchpoints.filter(t => t.type === 'Visit').length}
              </span>
            </div>
            <div className="flex justify-between text-sm mt-1">
              <span className="text-gray-600">Total Calls:</span>
              <span className="text-black">
                {completedTouchpoints.filter(t => t.type === 'Call').length}
              </span>
            </div>
            <div className="flex justify-between text-sm mt-1">
              <span className="text-gray-600">Progress:</span>
              <span className="text-black">
                {Math.round((completedTouchpoints.length / allTouchpoints.length) * 100)}%
              </span>
            </div>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}