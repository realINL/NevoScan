import './InstructionCard.css'

interface InstructionCardProps {
    title: string;
    instruction: string;
}

function InstructionCard({ title, instruction }: InstructionCardProps) {
    return ( 
        <div className='instruction-card' >
            {/* <img className='image-instruction' src={image}/> */}
            <h2 className='title'>{title}</h2>
            <p className='instruction'>{instruction}</p>
        </div>
     );
}

export default InstructionCard;