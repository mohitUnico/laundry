export const splitName = (name?: string | null): { firstName: string; lastName: string } => {
  if (!name) {
    return { firstName: '', lastName: '' };
  }

  const parts = name.trim().split(/\s+/); // collapse multiple spaces
  const firstName = parts[0] ?? '';
  const lastName = parts.slice(1).join(' ') || '';

  return { firstName, lastName };
};

export const combineName = (firstName?: string, lastName?: string): string => {
  const values = [firstName, lastName]
    .map((value) => (value ? value.trim() : ''))
    .filter(Boolean);

  if (values.length === 0) {
    return '';
  }

  return values.join(' ');
};


