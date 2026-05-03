interface InputProps {
  type?: 'text' | 'number';
  placeholder?: string;
  value: string | number;
  onChange: (value: string) => void;
  label?: string;
}

export function Input({ type = 'text', placeholder, value, onChange, label }: InputProps) {
  return (
    <div>
      {label && <label className="block text-sm font-medium text-gray-700 mb-1">{label}</label>}
      <input
        type={type}
        placeholder={placeholder}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
      />
    </div>
  );
}
