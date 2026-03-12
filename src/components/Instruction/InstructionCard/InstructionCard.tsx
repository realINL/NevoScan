import './InstructionCard.css'

interface InstructionCardProps {
    image: string;
    title: string;
    instruction: string;
}

function InstructionCard({ image, title, instruction }: InstructionCardProps) {
    return ( 
        <div className='instruction-card' >
            <img className='image-instruction' src={image}/>
            <h2 className='title'>{title}</h2>
            <p className='instruction'>{instruction}</p>
        </div>
     );
}

export default InstructionCard;