interface ToastProps {
  message: string;
  type?: 'success' | 'error';
  onClose: () => void;
}

export function Toast({ message, type = 'success', onClose }: ToastProps) {
  const styles = {
    success: 'bg-green-500',
    error: 'bg-red-500',
  };

  return (
    <div className={`fixed bottom-4 right-4 ${styles[type]} text-white px-6 py-3 rounded-lg shadow-lg`}>
      <div className="flex items-center gap-2">
        <span>{message}</span>
        <button onClick={onClose} className="ml-2">×</button>
      </div>
    </div>
  );
}
