import './ErrorView.css';

const DEFAULT_MESSAGE =
    'Произошла ошибка.\nПовторите попытку позже\nили обратитесь в поддержку';

type ErrorViewProps = {
    message?: string | null;
};

function ErrorView({ message }: ErrorViewProps) {
    const text = message?.trim() ? message.trim() : DEFAULT_MESSAGE;

    return (
        <div className="error-view">
            <p className="error-view__message">{text}</p>
        </div>
    );
}

export default ErrorView;
