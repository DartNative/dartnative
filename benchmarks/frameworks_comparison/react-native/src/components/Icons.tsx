import React from 'react';
import Svg, { Circle, Path } from 'react-native-svg';

type Props = { size?: number; color: string; strokeWidth?: number };

export function HomeIcon({ size = 24, color, strokeWidth = 1.75 }: Props) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round">
      <Path d="M3 10.5 12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z" />
    </Svg>
  );
}

export function SearchIcon({ size = 24, color, strokeWidth = 1.75 }: Props) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round">
      <Circle cx="11" cy="11" r="7" />
      <Path d="m20 20-3.5-3.5" />
    </Svg>
  );
}

export function CartIcon({ size = 24, color, strokeWidth = 1.75 }: Props) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round">
      <Path d="M6 7h12l-1 13H7z" />
      <Path d="M9 7a3 3 0 0 1 6 0" />
    </Svg>
  );
}

export function BackIcon({ size = 24, color, strokeWidth = 1.75 }: Props) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round">
      <Path d="m15 5-7 7 7 7" />
    </Svg>
  );
}

export function MinusIcon({ size = 16, color, strokeWidth = 2 }: Props) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={strokeWidth} strokeLinecap="round">
      <Path d="M5 12h14" />
    </Svg>
  );
}

export function PlusIcon({ size = 16, color, strokeWidth = 2 }: Props) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={strokeWidth} strokeLinecap="round">
      <Path d="M12 5v14M5 12h14" />
    </Svg>
  );
}

export function AlertIcon({ size = 48, color, strokeWidth = 1.25 }: Props) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round">
      <Circle cx="12" cy="12" r="9" />
      <Path d="M12 7.5v5.5" />
      <Path d="M12 16.5h.01" />
    </Svg>
  );
}
