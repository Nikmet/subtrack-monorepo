export type TopLoaderSnapshot = {
  requestCount: number;
  navigationCount: number;
};

type Listener = () => void;

const listeners = new Set<Listener>();

let snapshot: TopLoaderSnapshot = {
  requestCount: 0,
  navigationCount: 0,
};

const emit = () => {
  listeners.forEach((listener) => listener());
};

const updateSnapshot = (nextSnapshot: TopLoaderSnapshot) => {
  snapshot = nextSnapshot;
  emit();
};

export const subscribeTopLoader = (listener: Listener) => {
  listeners.add(listener);
  return () => listeners.delete(listener);
};

export const getTopLoaderSnapshot = () => snapshot;

export const beginTopLoaderRequest = () => {
  updateSnapshot({
    ...snapshot,
    requestCount: snapshot.requestCount + 1,
  });
};

export const endTopLoaderRequest = () => {
  updateSnapshot({
    ...snapshot,
    requestCount: Math.max(0, snapshot.requestCount - 1),
  });
};

export const beginTopLoaderNavigation = () => {
  updateSnapshot({
    ...snapshot,
    navigationCount: snapshot.navigationCount + 1,
  });
};

export const completeTopLoaderNavigation = () => {
  if (snapshot.navigationCount === 0) {
    return;
  }

  updateSnapshot({
    ...snapshot,
    navigationCount: 0,
  });
};
