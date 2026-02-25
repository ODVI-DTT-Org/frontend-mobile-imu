import { Button } from "./ui/button";
import { Badge } from "./ui/badge";

interface WireframeControlsProps {
  activeView: 'mobile' | 'desktop';
  onViewChange: (view: 'mobile' | 'desktop') => void;
  wireframeType: 'general' | 'login';
  onTypeChange: (type: 'general' | 'login') => void;
}

export function WireframeControls({ activeView, onViewChange, wireframeType, onTypeChange }: WireframeControlsProps) {
  return (
    <div className="flex items-center justify-between mb-6 p-4 bg-gray-50 rounded-lg border">
      <div className="flex items-center space-x-4">
        <h2>IMU</h2>
        <Badge variant="default">Interactive Mode</Badge>
        
        {/* Page Type Toggle */}
        <div className="flex space-x-1 ml-6">
          <Button
            variant={wireframeType === 'general' ? 'default' : 'outline'}
            size="sm"
            onClick={() => onTypeChange('general')}
          >
            General Layout
          </Button>
          <Button
            variant={wireframeType === 'login' ? 'default' : 'outline'}
            size="sm"
            onClick={() => onTypeChange('login')}
          >
            Login Page
          </Button>
        </div>
      </div>
      
      <div className="flex space-x-2">
        <Button
          variant={activeView === 'mobile' ? 'default' : 'outline'}
          size="sm"
          onClick={() => onViewChange('mobile')}
        >
          Mobile
        </Button>
        <Button
          variant={activeView === 'desktop' ? 'default' : 'outline'}
          size="sm"
          onClick={() => onViewChange('desktop')}
        >
          Desktop
        </Button>
      </div>
    </div>
  );
}