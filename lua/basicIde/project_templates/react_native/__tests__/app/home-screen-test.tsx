import { render } from '@testing-library/react-native';

import HomeScreen from '@/app/index';

jest.mock('react-native-worklets', () =>
  require('react-native-worklets/src/mock')
);

describe('<HomeScreen />', () => {
  test('Welcome text renders correctly on HomeScreen', async () => {
    const { getByText } = await render(<HomeScreen />);

    getByText('Welcome to Expo');
  });
});

