import { WireframeBox } from "./WireframeBox";

export function DesktopWireframe() {
  return (
    <div className="w-full max-w-4xl bg-white border-2 border-gray-300 rounded-lg shadow-lg p-6">
      <div className="mb-4 text-center">
        <h3 className="text-sm mb-2">Desktop Layout</h3>
        <div className="text-xs text-gray-500">1200px × 800px</div>
      </div>
      
      <div className="space-y-4">
        {/* Desktop Header */}
        <WireframeBox height="h-16" label="Header">
          <div className="flex items-center justify-between w-full px-8">
            <div className="w-32 h-8 bg-gray-300 rounded"></div>
            <div className="flex space-x-6">
              {["Home", "About", "Services", "Contact"].map((item) => (
                <div key={item} className="w-16 h-4 bg-gray-300 rounded"></div>
              ))}
            </div>
            <div className="w-24 h-8 bg-gray-400 rounded"></div>
          </div>
        </WireframeBox>

        {/* Hero Section */}
        <WireframeBox height="h-48" label="Hero Section">
          <div className="text-center">
            <div className="w-64 h-10 bg-gray-300 rounded mx-auto mb-4"></div>
            <div className="w-80 h-6 bg-gray-300 rounded mx-auto mb-4"></div>
            <div className="w-32 h-10 bg-gray-400 rounded mx-auto"></div>
          </div>
        </WireframeBox>

        {/* Main Content Area */}
        <div className="flex gap-6">
          {/* Main Content */}
          <div className="flex-1 space-y-4">
            <WireframeBox height="h-8" label="Section Title">
              <div className="w-48 h-6 bg-gray-300 rounded"></div>
            </WireframeBox>
            
            {/* Content Grid */}
            <div className="grid grid-cols-2 gap-4">
              {[1, 2, 3, 4].map((i) => (
                <WireframeBox key={i} height="h-32" label={`Feature ${i}`}>
                  <div className="text-center">
                    <div className="w-16 h-16 bg-gray-300 rounded mx-auto mb-2"></div>
                    <div className="w-20 h-4 bg-gray-300 rounded mx-auto mb-1"></div>
                    <div className="w-24 h-3 bg-gray-300 rounded mx-auto"></div>
                  </div>
                </WireframeBox>
              ))}
            </div>
          </div>

          {/* Sidebar */}
          <div className="w-64 space-y-3">
            <WireframeBox height="h-8" label="Sidebar Title">
              <div className="w-32 h-6 bg-gray-300 rounded"></div>
            </WireframeBox>
            
            {[1, 2, 3].map((i) => (
              <WireframeBox key={i} height="h-20" label={`Widget ${i}`}>
                <div className="w-full px-4">
                  <div className="w-24 h-4 bg-gray-300 rounded mb-2"></div>
                  <div className="w-32 h-3 bg-gray-300 rounded mb-1"></div>
                  <div className="w-28 h-3 bg-gray-300 rounded"></div>
                </div>
              </WireframeBox>
            ))}
          </div>
        </div>

        {/* Footer */}
        <WireframeBox height="h-20" label="Footer">
          <div className="flex justify-between items-center w-full px-8">
            <div className="flex space-x-8">
              <div className="w-24 h-4 bg-gray-300 rounded"></div>
              <div className="w-20 h-4 bg-gray-300 rounded"></div>
              <div className="w-28 h-4 bg-gray-300 rounded"></div>
            </div>
            <div className="flex space-x-4">
              {[1, 2, 3].map((i) => (
                <div key={i} className="w-6 h-6 bg-gray-300 rounded"></div>
              ))}
            </div>
          </div>
        </WireframeBox>
      </div>
    </div>
  );
}