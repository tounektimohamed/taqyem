from flask import Flask, request, jsonify, render_template, make_response
from fpdf import FPDF
import json

app = Flask(__name__)

class PDF(FPDF):
    def header(self):
        self.set_font('Arial', 'B', 12)
        self.cell(0, 10, 'Tableau des Résultats', 0, 1, 'C')

    def footer(self):
        self.set_y(-15)
        self.set_font('Arial', 'I', 8)
        self.cell(0, 10, f'Page {self.page_no()}', 0, 0, 'C')

@app.route('/generate_pdf', methods=['POST'])
def generate_pdf():
    data = request.json

    pdf = PDF()
    pdf.add_page()
    pdf.set_font('Arial', 'B', 12)

    # En-tête
    pdf.cell(0, 10, f"Professeur: {data['profName']}", 0, 1)
    pdf.cell(0, 10, f"Matière: {data['matiereName']}", 0, 1)
    pdf.cell(0, 10, f"Classe: {data['className']}", 0, 1)
    pdf.cell(0, 10, f"École: {data['schoolName']}", 0, 1)
    pdf.ln(10)

    # Tableau
    pdf.set_font('Arial', 'B', 10)
    pdf.cell(40, 10, 'Nom et Prénom', 1, 0, 'C')
    for bareme in data['baremes']:
        pdf.cell(30, 10, bareme['value'], 1, 0, 'C')
    pdf.ln()

    pdf.set_font('Arial', '', 10)
    for student in data['students']:
        pdf.cell(40, 10, student['name'], 1, 0, 'C')
        for bareme in data['baremes']:
            pdf.cell(30, 10, student['baremes'].get(bareme['id'], '( - - - )'), 1, 0, 'C')
        pdf.ln()

    # Ligne pour la somme des élèves avec les critères +++ et ++-
    pdf.set_font('Arial', 'B', 10)
    pdf.cell(40, 10, 'Nombre d\'élèves ayant atteint le seuil minimal', 1, 0, 'C')
    for bareme in data['baremes']:
        pdf.cell(30, 10, str(data['sumCriteriaMaxPerBareme'].get(bareme['id'], 0)), 1, 0, 'C')
    pdf.ln()

    # Ligne pour le pourcentage
    pdf.cell(40, 10, 'Pourcentage d\'élèves ayant atteint le seuil', 1, 0, 'C')
    for bareme in data['baremes']:
        percentage = (data['sumCriteriaMaxPerBareme'].get(bareme['id'], 0) / data['totalStudents']) * 100
        pdf.cell(30, 10, f'{percentage:.2f}%', 1, 0, 'C')
    pdf.ln()

    response = make_response(pdf.output(dest='S').encode('latin1'))
    response.headers.set('Content-Disposition', 'attachment', filename='tableau_resultats.pdf')
    response.headers.set('Content-Type', 'application/pdf')

    return response

if __name__ == '__main__':
    app.run(debug=True)