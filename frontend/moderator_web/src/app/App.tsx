import { RouterProvider } from 'react-router';
import { SessionGate } from '@features/auth';
import { router } from './router';

function App() {
	return (
		<SessionGate>
			<RouterProvider router={router} />
		</SessionGate>
	);
}

export default App;
