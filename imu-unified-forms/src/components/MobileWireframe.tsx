import { WireframeBox } from "./WireframeBox";

export function MobileWireframe() {
  return (
    <div className="w-80 bg-white border-2 border-gray-300 rounded-lg shadow-lg p-4">
      <div className="mb-4 text-center">
        <h3 className="text-sm mb-2">Mobile Layout</h3>
        <div className="text-xs text-gray-500">375px × 812px</div>
      </div>
      
      <div className="space-y-3">
        {/* Mobile Header */}
        <WireframeBox height="h-14" label="Header">
          <div className="flex items-center justify-between w-full px-4">
            <div className="w-6 h-6 bg-gray-300 rounded"></div>
            <div className="w-20 h-4 bg-gray-300 rounded"></div>
            <div className="w-6 h-6 bg-gray-300 rounded"></div>
          </div>
        </WireframeBox>

        {/* Hero Section */}
        <WireframeBox height="h-32" label="Hero">
          <div className="text-center">
            <div className="w-24 h-6 bg-gray-300 rounded mx-auto mb-2"></div>
            <div className="w-32 h-4 bg-gray-300 rounded mx-auto mb-2"></div>
            <div className="w-20 h-8 bg-gray-400 rounded mx-auto"></div>
          </div>
        </WireframeBox>

        {/* Content Cards */}
        <div className="space-y-2">
          {[1, 2, 3].map((i) => (
            <WireframeBox key={i} height="h-24" label={`Card ${i}`}>
              <div className="flex items-center space-x-3 w-full px-4">
                <div className="w-12 h-12 bg-gray-300 rounded"></div>
                <div className="flex-1">
                  <div className="w-24 h-4 bg-gray-300 rounded mb-1"></div>
                  <div className="w-32 h-3 bg-gray-300 rounded"></div>
                </div>
              </div>
            </WireframeBox>
          ))}
        </div>

        {/* Mobile Navigation */}
        <WireframeBox height="h-16" label="Bottom Nav">
          <div className="flex justify-around items-center w-full">
            {[1, 2, 3, 4].map((i) => (
              <div key={i} className="w-6 h-6 bg-gray-300 rounded"></div>
            ))}
          </div>
        </WireframeBox>
      </div>
    </div>
  );
}