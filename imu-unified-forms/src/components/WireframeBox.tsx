interface WireframeBoxProps {
  width?: string;
  height?: string;
  className?: string;
  children?: React.ReactNode;
  label?: string;
}

export function WireframeBox({ width = "w-full", height = "h-8", className = "", children, label }: WireframeBoxProps) {
  return (
    <div className={`${width} ${height} bg-gray-200 border-2 border-dashed border-gray-400 flex items-center justify-center relative ${className}`}>
      {label && (
        <span className="text-xs text-gray-500 absolute top-1 left-1 bg-white px-1">
          {label}
        </span>
      )}
      {children && (
        <div className="text-xs text-gray-600 text-center px-2">
          {children}
        </div>
      )}
    </div>
  );
}